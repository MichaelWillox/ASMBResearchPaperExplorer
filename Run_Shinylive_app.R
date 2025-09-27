## Convert the shiny app into the assets for running the app in a browser

unlink("docs", recursive = TRUE, force = TRUE) 

dir.create("docs")

shinylive::export(
 appdir = "app",
 destdir = "docs"
)

## Run the following in an R session to serve the app:
httpuv::runStaticServer("docs", port = 8008, browse = TRUE)

