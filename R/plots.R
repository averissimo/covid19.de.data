age.plot.state <- function(dat, var, filter.state, title) {
  pyramid <- dat %>%
    filter(length(filter.state) == 0 | state %in% filter.state) %>%
    filter(gender %in% c('M', 'W')) %>%
    group_by(state, age.group, gender) %>%
    summarize(cases = sum(cases),
              deaths = sum(deaths)) %>%
    mutate(cases = if_else(gender == 'M', -1 * cases, cases),
           deaths = if_else(gender == 'M', -1 * deaths, deaths))

  ggplot(pyramid, aes_(x = ~age.group, y = as.name(var), fill = ~gender)) +   # Fill column
    geom_bar(stat = "identity", width = .6) +   # draw the bars
    scale_y_continuous(labels = abs) +
    coord_flip() +  # Flip axes
    theme_clean() +  # Tufte theme from ggfortify
    theme(plot.title = element_text(hjust = .5),
          axis.ticks = element_blank()) +   # Centre plot title
    scale_fill_viridis_d('Gender', end = .7) + # Color palette
    theme(legend.position = c(0.5,.5)) +
    labs(title= title,
         x = 'Age Groups',
         y = title) +
    facet_wrap(~state, ncol = 2)
}

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
    theme_clean() +  # Tufte theme from ggfortify
    theme(plot.title = element_text(hjust = .5),
          axis.ticks = element_blank()) +   # Centre plot title
    scale_fill_viridis_d('Gender', end = .7) + # Color palette
    theme(legend.position = c(0.5,.5)) +
    labs(title= title,
         x = 'Age Groups',
         y = title) +
    facet_wrap(~district, ncol = 2)
}
