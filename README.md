
# Snohomish

## Overview

This package provides a front-end interface to WDFWs SG (spawning
ground) database. The package is in an early developmental state. It is
intended to serve as a temporary bridge to enable WDFW biologists
working in the Snohomish Basin to enter and edit data until a permanent
solution can be built using our standard NodeJS Angular framework. This
application will only work for those who have been granted appropriate
permissions to the database…a tightly restricted group. No credentials
are stored in the R code. If you do not have permissions to the
database, but want to explore the functionality, you will need to create
and host your own database separately. You will then need to edit the
connection string in the global.R file. Also, each user will need to set
up connection credentials using an `.Renviron` file. A create script for
the database can be requested. You can also find the most recent version
of the SG data dictionary at: <https://arestrom.github.io/sgsdd/>

## Installation

You will need to install R-4.0.2 or higher. You will also need some
non-CRAN packages.

``` r
# install.packages("remotes")
remotes::install_github("arestrom/iformr")
```

## Storing database connection credentials

In order to use this application you **must** first be granted
permissions to the SG database. You will then need to enter your
credentials into your `.Renviron` file. Instructions on how to add
credentials to your `.Renviron` file can be found in the Appendix
section of:
<https://cran.r-project.org/web/packages/httr/vignettes/api-packages.html>

## Start and stop the application

Before launching the application you are strongly advised to make sure
your default browser is set to something like `Chrome` or `Firefox`. The
interface is unlikely to work correctly using a Microsoft browser. To
make sure that the application starts in your browser rather than the
default RStudio Viewer, open the `global.R` file in RStudio. You should
see a green triangle icon next to `Run App` in the upper right-hand
corner of you script pane. Click on the dialog icon to the right of `Run
App` and select `Run External`. This only needs to be done once. Any
time afterward that you want to start the application you just need to
click on `Run App`.

Once the application is running you should see a red icon in the upper
right-hand corner of the console indicating an active session. At the
bottom of the RStudio console you should see something like:

`Listening on http://127.0.0.1:1234`

To stop the application close the web-interface in your browser. Then
make sure to click on the red `Stop` icon in the upper right-hand corner
of the RStudio console. This ends the active session. You should see the
normal R prompt `>` at the bottom of the console window return. Make
sure and stop the session as soon as you close the web interface in your
browser so as to release any unneeded resources.
