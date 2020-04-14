#' Plot age distribution of federal states
#'
#' @param dat data
#' @param var variable to separate
#' @param filter.state keep only these
#' @param title title of plot
#'
#' @return ggplot
age.plot.state <- function(dat, var, filter.state, title, legend.center = TRUE, subtitle = 'Showing only 8 most afected states') {
  pyramid <- dat %>%
    filter(length(filter.state) == 0 | state %in% filter.state) %>%
    filter(gender %in% c('M', 'W')) %>%
    group_by(state, age.group, gender) %>%
    summarize(cases = sum(cases),
              deaths = sum(deaths)) %>%
    mutate(cases = if_else(gender == 'M', -1 * cases, cases),
           deaths = if_else(gender == 'M', -1 * deaths, deaths))

  my.plot <- ggplot(pyramid, aes_(x = ~age.group, y = as.name(var), fill = ~gender)) +   # Fill column
    geom_bar(stat = "identity", width = .6) +   # draw the bars
    scale_y_continuous(labels = abs) +
    coord_flip() +  # Flip axes
    theme_minimal() +  # Tufte theme from ggfortify
    theme(plot.title = element_text(hjust = .5),
          axis.ticks = element_blank()) +   # Centre plot title
    scale_fill_viridis_d('Gender', end = .7) + # Color palette
    labs(title= title,
         x = 'Age Groups',
         y = title,
         subtitle = subtitle) +
    facet_wrap(~state, ncol = 2)

  if (legend.center) {
    my.plot <- my.plot + theme(legend.position = c(0.5,.5))
  }
  return(my.plot)
}

#' Plot age distribution of districts
#'
#' @param dat data
#' @param var variable to separate
#' @param filter.district keep only these
#' @param title title of plot
#'
#' @return ggplot
age.plot.district <- function(dat, var, filter.district, title) {
  pyramid <- dat %>%
    filter(length(filter.district) == 0 | district %in% filter.district) %>%
    filter(gender %in% c('M', 'W')) %>%
    group_by(district, age.group, gender) %>%
    summarize(cases = sum(cases),
              deaths = sum(deaths)) %>%
    mutate(cases = if_else(gender == 'M', -1 * cases, cases),
           deaths = if_else(gender == 'M', -1 * deaths, deaths))

  ggplot(pyramid, aes_(x = ~age.group, y = as.name(var), fill = ~gender)) +   # Fill column
    geom_bar(stat = "identity", width = .6) +   # draw the bars
    scale_y_continuous(labels = abs) +
    coord_flip() +  # Flip axes
    theme_minimal() +  # Tufte theme from ggfortify
    theme(plot.title = element_text(hjust = .5),
          axis.ticks = element_blank()) +   # Centre plot title
    scale_fill_viridis_d('Gender', end = .7) + # Color palette
    theme(legend.position = c(0.5,.5)) +
    labs(title= title,
         x = 'Age Groups',
         y = title,
         subtitle = 'Showing only 8 most afected districts') +
    facet_wrap(~district, ncol = 2)
}

#' Show top 30 cases
#'
#' @param dat data
#' @param case.type type of case
#' @param region.code state or district
#' @param n number to keep
#'
#' @return ggplot
top30 <- function(dat, case.type, region.code, n = 30) {
  my.plot <- dat %>%
    filter(type == case.type) %>%
    group_by(state, type) %>%
    summarise(cases = sum(cases)) %>%
    arrange(cases) %>%
    ungroup() %>%
    mutate(state = paste0(state, ' (', format(cases, big.mark = ',', trim = TRUE), ')')) %>%
    mutate(state = factor(state, levels = unique(.$state))) %>%
    top_n(n, cases) %>%
    ggplot() +
    geom_bar(aes(state, cases, fill = state), stat = 'identity') +
    # scale_y_continuous(trans = 'log10') +
    coord_flip() +
    labs(y = '{proper.cases(case.type, capitalize = TRUE)}' %>% glue,
         x = region.code,
         title = '\'{proper.cases(case.type, capitalize.all = TRUE)}\' by {region.code}' %>% glue ,
         caption = last.date.string) +
    theme_minimal() +
    theme(legend.position = 'none')

  return(my.plot)
}


#' Convert to proper case
#'
#' @param value confirmed or death strings
#' @param capitalize capitalize only first word
#' @param capitalize.all capitalize all words
#'
#' @return string with the proper mapping
proper.cases <- function(value, capitalize = FALSE, capitalize.all = FALSE) {
  val = (if_else(value == 'confirmed', 'confirmed cases', if_else(value == 'death', 'deaths', if_else(value == 'all', 'cases', value))))
  if (capitalize.all) {
    return(loose.rock::proper(val))
  } else if (capitalize) {
    substring(val, 1, 1) = toupper(substring(val, 1, 1))
    return(val)
  } else {
    return(val)
  }
}
