#' Scrapea las entradas resultantes de una búsqueda en meneame.com
#'
#' @param palabra Character. Palabra(s) que se quiere buscar en meneame.net para scrapear. Importante no introducir más de un espacio entre palabras.
#' @param paginas Numeric. Número de páginas que se quieren scraper de los resultados de la búsqueda. Como máximo 40.
#' @param ruta Character. Ruta en el ordenador donde se quiere el csv. Por defecto se guardará un csv llamado meneame.csv en el directorio de trabajo.
#'
#' @return Un csv que se guarda en la ruta indicada.
#' @import stringr
#' @import rvest
#' @import httr
#' @importFrom  readr write_csv
#' @importFrom readr read_csv
#' @import utils
#' @import xml2
#' @export
busca <- function(palabra, paginas, ruta = "~/meneame.csv") {
  start <- Sys.time()



  #require(stringr)
  #require(rvest)
  #require(httr)
  #require(readr)
  #require(xml2)


  desktop_agents <-  c('Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/54.0.2840.99 Safari/537.36',
                       'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/54.0.2840.99 Safari/537.36',
                       'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/54.0.2840.99 Safari/537.36',
                       'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_1) AppleWebKit/602.2.14 (KHTML, like Gecko) Version/10.0.1 Safari/602.2.14',
                       'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/54.0.2840.71 Safari/537.36',
                       'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/54.0.2840.98 Safari/537.36',
                       'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/54.0.2840.98 Safari/537.36',
                       'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/54.0.2840.71 Safari/537.36',
                       'Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/54.0.2840.99 Safari/537.36',
                       'Mozilla/5.0 (Windows NT 10.0; WOW64; rv:50.0) Gecko/20100101 Firefox/50.0')



  palabra <- str_replace(palabra, " ", "+")

  pags <- 1:paginas
  relevantes <- paste0("https://www.meneame.net/search?page=", pags,"&q=", palabra, "&w=links&p=&s=&h=&o=&u=")
  porfecha <- paste0("https://www.meneame.net/search?page=", pags,"&q=", palabra, "&w=links&p=&s=&h=&o=date&u=")

  urls <- c(relevantes, porfecha)

  if (paginas < 1) {
    stop("Error: Es imposible scrapear menos de una página.")
  }

  line <- data.frame("fecha", "titular", "entradilla", "meneos", "clics", "comments", "positivos", "negativos", "anonimos", "karma", "user", "medio", "subname", "links")
  write_csv(x = line, append = FALSE, path = ruta, col_names = FALSE)

  for (url in urls){
    x <- GET(url, add_headers('user-agent' = desktop_agents[sample(1:10, 1)]))

    titulares <- x %>% read_html() %>% html_nodes("h2 a") %>% html_text()

    entradilla <- x %>% read_html() %>% html_nodes(".news-content") %>% html_text()

    links <- x %>% read_html() %>% html_nodes("h2 a") %>% html_attr(name = "href")

    meneos <- as.numeric(x %>% read_html() %>% html_nodes(".news-body .news-shakeit .votes a") %>% html_text())
    clics <- x %>% read_html() %>% html_nodes(".news-body .news-shakeit .clics") %>% html_text()
    clics <- as.numeric(str_remove(clics, " clics"))

    comments <- x %>% read_html() %>% html_nodes(".news-body .comments") %>% html_text()
    comments[str_detect(comments, "sin comentarios")] <- "0"
    comments <- as.numeric(str_remove(comments, " comentarios"))

    positivos <- as.numeric(x %>% read_html() %>% html_nodes(".news-details-data-down .votes-up") %>% html_text())

    negativos <- as.numeric(x %>% read_html() %>% html_nodes(".news-details-data-down .votes-down") %>% html_text())

    anonimos <- as.numeric(x %>% read_html() %>% html_nodes(".news-details-data-down .wideonly") %>% html_text())

    karma <- as.numeric(x %>% read_html() %>% html_nodes(".news-details-data-down .karma-value") %>% html_text())

    subname <-  x %>% read_html() %>% html_nodes(".news-details-data-down .sub-name") %>% html_text()

    medio <- x %>% read_html() %>% html_nodes(".news-submitted .showmytitle") %>% html_text()

    user <-  x %>% read_html() %>% html_nodes(".news-submitted a") %>% html_text()
    user <- user[user != ""]

    fecha <- x %>% read_html() %>% html_nodes(".promoted-article .visible , .showmytitle+ .visible") %>% html_attr(name = "data-ts")
    fecha <- fecha[fecha != ""]
    fecha <- as.numeric(fecha)
    fecha <- as.POSIXct(fecha, origin = "1970-01-01")

    if (length(fecha) != length(titulares)) {
      fecha <- fecha[1:length(titulares)]
    }


    # Creo la columna medio a partir de los links

    medio <- links

    medio <- str_remove_all(medio, "https://|http://|www.")

    medio <- str_split(medio, pattern = "/", n = 2, simplify = TRUE)
    medio <- medio[,1]

    medio <- str_remove(medio, "apuntesdeclase.")
    medio <- str_replace(medio, "20minutos.com", "20minutos.es")
    medio <- str_replace(medio, "m.20minutos.es", "20minutos.es")
    medio <- str_remove_all(medio, "es.noticias.|espanol.news.|finance.")

    try(line <- data.frame(fecha, titulares, entradilla, meneos, clics, comments, positivos, negativos, anonimos, karma, user, medio, subname, links))
    print(head(line))
    write_csv(x = line, append = TRUE, path = ruta, col_names = FALSE)


    Sys.sleep(sample(x = 1:2, size = 1))  ## Duerme entre uno y tres segundos entre página y página

  }

  stop <- Sys.time()

  meneos <<- read_csv(ruta)

  difftime(stop, start, units = "auto")
}
