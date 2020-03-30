#' Write range for SQL query in ARCGIS
#'
#' @param a start of range of ObjectId
#' @param b end of range of ObjectId
#'
#' @return a string that can be used in a where clause of sql
#' @export
#'
#' @examples
#' range.write(1, 10)
#' range.write(1, 1)
range.write <- function(a, b) {
  if (a == b) {
    'ObjectId = {a}' %>%
      glue::glue() %>%
      return()
  } else {
    '(ObjectId >= {a} AND ObjectId <= {b})' %>%
      glue::glue() %>%
      return()
  }
}


#' Algorithm to pick up a vector and find all ranges in it
#'
#' @param dat vector of numbers
#' @param key.fun callback function to write ranges
#'
#' @return vector of strings defining all ranges in data
#' @export
#'
#' @examples
#' identify.ranges(c(1:3, 5, 7:8, 10:12, 14:15))
#' identify.ranges(c(1:3, 5, 7:8, 10:12, 14))
#' identify.ranges(c(1, 5, 7:8, 10:12, 14))
#' identify.ranges(c(1, 5, 7:8, 10:12, 14:19))
#' identify.ranges(rki.covid19 %>% pull(object.id) %>% unique %>% sort)
identify.ranges <- function(dat, key.fun = range.write) {
  ranges <- c()
  if (length(dat) <= 1) {
    return(ranges)
  }

  prev.val <- dat[1]
  ix.start <- 1
  included.last <- FALSE

  dat <- dat %>% sort %>% unique

  for (ix in seq_along(dat)[-1]) {
    val <- dat[ix]
    if (prev.val + 1 != val) {
      ranges <- c(ranges, key.fun(dat[ix.start], dat[ix - 1]))
      ix.start <- ix

      if(ix == length(dat)) {
        ranges <- c(ranges, key.fun(dat[ix], dat[ix]))
      }
    } else if(ix == length(dat)) {
      ranges <- c(ranges, key.fun(dat[ix.start], dat[ix]))
    }


    prev.val <- val
  }
  return(ranges)
}


#' Download state specific data
#'
#' @param id.state number that goes from 1 to 16
#' @param max.record maximum number of records to download on each HTTP GET call
#' @param force.all force to get all data (ignoring already existing records on rki.covid19 data)
#'
#' @return data frame with all the data. Column name are translated from German
#' @export
#'
#' @examples
#' download.state(1)
#' download.state(2)
download.state <- function(id.state, max.record = 500, force.all = FALSE) {
  dta     <- tibble()
  offset  <- 0
  stop.me <- FALSE

  if (exists('rki.district.data::rki.covid19')) {
      dta.tmp <- rki.covid19 %>% dplyr::filter(id.state == id.state)

      if (nrow(dta.tmp) > 0) {
        dta <- dta.tmp
      }
      dta.tmp <- NULL

      exclude.ids <- if (!force.all) {
        exclude.ids <- rki.district.data::rki.covid19 %>%
          dplyr::pull(object.id) %>%
          unique %>%
          sort %>%
          identify.ranges %>%
          paste(collapse = ' OR ') %>%
          paste0('NOT (', ., ')')
      } else {
        NULL
      }
  } else {
    exclude.ids = c()
  }

  # Download chunks of 500
  while (!stop.me) {
    dta.tmp <- download.raw(id.state, offset = offset, max.record = max.record, exclude.ids = exclude.ids)

    if (nrow(dta.tmp) == 0) {
      futile.logger::flog.debug('No rows returned for \'id.state\' == %d (offset = %d, max.record = %d)\n  Stopping for this state...', id.state, offset, max.record)
      break
    }
    # else

    dta <- dta %>% dplyr::bind_rows(dta.tmp)

    if (nrow(dta.tmp) == max.record) {
      offset <- offset + max.record
      Sys.sleep(.1)
      next
    } else {
      stop.me <- TRUE
      break
    }
  }

  return(dta)
}

#' Download call to ARCGIS
#'
#' @param id.state German state id (from 1 to 16)
#' @param offset offset on number of records for call
#' @param max.record maximum number of records to download in call
#' @param exclude.ids exclude ids from data
#'
#' @return data frame with data. Column names are translated from German
download.raw <- function(id.state, offset = 0, max.record = 1000, exclude.ids = NULL) {
  # build query
  if (is.null(exclude.ids)) {
    query <- 'IdBundesland = {id.state}' %>%
      glue::glue()
  } else {
    query <- 'IdBundesland = {id.state} AND {exclude.ids}' %>%
      glue::glue()
  }

  # build url for query
  url.base <- 'https://services7.arcgis.com'
  url.key  <- 'mOBPykOjAyBO2ZKk'
  url.path <- 'arcgis/rest/services/RKI_COVID19/FeatureServer/0/query'
  url.query = list(
    outStatistics ='',
    having = '',
    objectIds = '',
    returnIdsOnly = 'false',
    returnUniqueIdsOnly = 'false',
    returnCountOnly = 'false',
    returnDistinctValues = 'false',
    cacheHint = 'false',
    time = '',
    resultType = 'none',
    sqlFormat = 'none',
    token = '',
    ###
    ###
    ###
    where = query,
    #
    f = 'json',
    outFields = '*',
    orderByFields = 'Meldedatum',
    resultOffset = format(offset),
    resultRecordCount = format(max.record)
  )
  url.str = '{url.base}/{url.key}/{url.path}' %>% glue::glue()

  response <- httr::GET(url.str, query = url.query)

  # query url
  json_data <- httr::content(response, 'text', encoding = 'UTF-8') %>%
    rjson::fromJSON()

  if (!is.null(json_data$exceededTransferLimit) &&
      json_data$exceededTransferLimit && length(json_data$features) > max.record) {
    transfer.limit.reached <<- json_data
    stop('Exceeded transfer limit!!')
  }

  '  {length(json_data$feature)} lines were downloaded' %>%
    glue::glue() %>%
    futile.logger::flog.debug()


  # build results
  dta <- tibble()
  if (length(json_data$features) == 0) {
    return(dta)
  }

  for (ix in seq(length(json_data$features)) ) {
    new.line <- dplyr::bind_rows(json_data$feature[[ix]])
    dta <- dplyr::bind_rows(dta, new.line)
  }

  dta %>%
    dplyr::mutate(Meldedatum = anytime::anytime(Meldedatum / 1000)) %>%
    dplyr::select(id.state = IdBundesland,
           state = Bundesland,
           id.district = IdLandkreis,
           district = Landkreis,
           gender = Geschlecht,
           cumul.cases = AnzahlFall,
           cumul.deaths = AnzahlTodesfall,
           object.id = ObjectId,
           registration.date = Meldedatum,
           # date.status = Datenstand, # removed as it will only show a meaningless date
           cases = NeuerFall,
           deaths = NeuerTodesfall) %>%
    return()
}
