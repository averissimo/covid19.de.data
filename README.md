Germany data on district level
================

> COVID-19 District level data from Robert Koch Institute in Germany

The data is updated daily and is downloaded from a ARCGIS REST API using
the
[RKI\_COVID19](https://services7.arcgis.com/mOBPykOjAyBO2ZKk/arcgis/rest/services/RKI_COVID19/FeatureServer/0/query?where=Meldedatum+%3E+\(CURRENT_TIMESTAMP+-+3\)&objectIds=&time=&resultType=none&outFields=*&returnIdsOnly=false&returnUniqueIdsOnly=false&returnCountOnly=false&returnDistinctValues=false&cacheHint=false&orderByFields=Meldedatum&outStatistics=&having=&resultOffset=&resultRecordCount=&sqlFormat=none&f=html&token=)
feature server.

Data from previous dates can be changed over time and update the data
files accordingly, therefore `object.id` for any given row will change
daily.

Source code available at
[averissimo/covid19-rki\_de-data](https://github.com/averissimo/covid19-de_rki-data).

**Other covid-19
    related:**

  - [World](https://averissimo.github.io/covid19-analysis/)
  - [Germany](https://averissimo.github.io/covid19-analysis/germany.html)
    *(by state)*
  - [Italy](https://averissimo.github.io/covid19-analysis/italy.html)
    *(by regione)*
  - [Bavaria](https://averissimo.github.io/covid19-analysis/bayer.html)
    *(Germany)*

## Install / Usage

The data is available inside the `data/` folder in `.csv` format.

It can also be used as an *R package* by installing this repository
directly:

``` r
> BiocManager::install_github('averissimo/covid19-de_rki-data')
# or
> devtools::install_github('averissimo/covid19-de_rki-data')
```

## Update data

To retrieve the lastest yourself use the following function of the R
package.

``` r
> rki.de.district.data::update.dataset()
```

Note that, as of now, the data is updated by the Robert Koch Institute
once a
day.

## Data visualization

### Cases by Federal State

#### Confirmed cases

![](README_files/figure-gfm/unnamed-chunk-8-1.png)<!-- -->

#### Deaths

![](README_files/figure-gfm/unnamed-chunk-9-1.png)<!-- -->

### Cases by Districts *(Showing only 50 districts with most cases/deaths)*

#### Confirmed cases

*Showing only 50*

![](README_files/figure-gfm/unnamed-chunk-10-1.png)<!-- -->

#### Deaths

*Showing only 50*

![](README_files/figure-gfm/unnamed-chunk-11-1.png)<!-- -->

### New cases/deaths per day *in most affected states/districts*

#### New Cases in states

![](README_files/figure-gfm/unnamed-chunk-12-1.png)<!-- -->

#### New Deaths in states

![](README_files/figure-gfm/unnamed-chunk-13-1.png)<!-- -->

#### New cases in districts

![](README_files/figure-gfm/unnamed-chunk-14-1.png)<!-- -->

#### New deaths in districts

![](README_files/figure-gfm/unnamed-chunk-15-1.png)<!-- -->

### Total cases in last 12 days *in most affected states/districts*

#### Total cases in states

![](README_files/figure-gfm/unnamed-chunk-16-1.png)<!-- -->

#### Total deaths in states

Showing only 6 states most affected

![](README_files/figure-gfm/unnamed-chunk-17-1.png)<!-- -->

#### Total cases in districs

Showing only 6 districs most affected

![](README_files/figure-gfm/unnamed-chunk-18-1.png)<!-- -->

#### Total deaths in districs

Showing only 6 districs most affected

![](README_files/figure-gfm/unnamed-chunk-19-1.png)<!-- -->

### Cases by age groups

#### Cases in states

![](README_files/figure-gfm/unnamed-chunk-20-1.png)<!-- -->

#### Deaths in states

![](README_files/figure-gfm/unnamed-chunk-21-1.png)<!-- -->

#### Cases in districts

![](README_files/figure-gfm/unnamed-chunk-22-1.png)<!-- -->

#### Deaths in districts

![](README_files/figure-gfm/unnamed-chunk-23-1.png)<!-- -->
