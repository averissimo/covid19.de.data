#' Add factors to rki data
#'
#' @param dat rki.de.data
#'
#' @return data frame with factors as columns for age.group, district, id.district, state, id.state
#' @export
#'
#' @examples
add.factors <- function(dat) {
  my.levels <- c('unbekannt', unique(dat$age.group) %>% sort) %>% unique
  my.labels <- paste('Age', my.levels %>% gsub('A', '', .) %>% gsub('unbekannt', '??-??', .))

  state.levels <- group_by(dat, id.state, state) %>% summarize(rank = sum(cases)) %>% arrange(-rank)
  district.levels <- group_by(dat, id.district, district) %>% summarize(rank = sum(cases)) %>% arrange(-rank)

  dat %>%
    mutate(
         age.group   = factor(age.group, levels = my.levels, labels = my.labels),
         district    = factor(district, levels = district.levels %>% pull(district) %>% unique()),
         id.district = factor(id.district, levels = district.levels %>% pull(id.district) %>% unique()),
         state       = factor(state, levels = state.levels %>% pull(state) %>% unique()),
         id.state    = factor(id.state, levels = state.levels %>% pull(id.state) %>% unique())) %>%
    return()
}

#' Update dataset
#'
#' @return nothing
#' @export
#'
#' @examples
#' update.dataset()
update.dataset <- function() {
  data("rki.covid19")

  rki.covid19.tmp <- tibble()
  rki.covid19.tmp <- download.state(rki.covid19)

  rki.covid19.tmp <- rki.covid19.tmp %>%
    arrange(desc(date)) %>%
    mutate(date = anydate(format(date, '%Y/%m/%d')))

  if (!exists('rki.covid19') || (!all(rki.covid19.tmp$object.id %in% rki.covid19$object.id))) {
    flog.info('Data returned from this function was updated.')
  } else {
    flog.info('Data is up to date, nothing to do...')
  }
  return(rki.covid19.tmp)
}

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
download.state <- function(existing.data = tibble(), max.record = 500) {
  dta     <- tibble()
  offset  <- 0
  stop.me <- FALSE

  dta.tmp <- existing.data

  if (nrow(dta.tmp) > 0) {
    dta <- dta.tmp

    exclude.ids <- existing.data %>%
      dplyr::pull(object.id) %>%
      unique %>%
      sort %>%
      identify.ranges %>%
      paste(collapse = ' OR ') %>%
      paste0('NOT (', ., ')')
  } else {
    exclude.ids <- NULL
  }
  dta.tmp <- NULL

  # Download chunks of 500
  while (!stop.me) {
    dta.tmp <- download.raw(offset = offset, max.record = max.record, exclude.ids = exclude.ids)

    if (nrow(dta.tmp) == 0) {
      futile.logger::flog.debug('No rows returned (offset = %d, max.record = %d)\n  Stopping...', offset, max.record)
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
download.raw <- function(offset = 0, max.record = 1000, exclude.ids = NULL) {
  # build query
  if (is.null(exclude.ids)) {
    query <- 'IdBundesland > 0'
  } else {
    query <- '{exclude.ids}' %>%
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

  if (length(json_data$feature) > 0) {
    '...{length(json_data$feature)} lines were downloaded' %>%
      glue::glue() %>%
      futile.logger::flog.info()
  }

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
    dplyr::select(date = Meldedatum,
                  # date.status = Datenstand, # removed as it will only show a meaningless date
                  id.state = IdBundesland,
                  state = Bundesland,
                  id.district = IdLandkreis,
                  district = Landkreis,
                  age.group = Altersgruppe,
                  gender = Geschlecht,
                  cases = AnzahlFall,
                  deaths = AnzahlTodesfall,
                  object.id = ObjectId,
                  ) %>%
    return()
}
