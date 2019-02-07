#' @title Cats in R console.
#' @name kittyR
#' @author \href{https://github.com/IndrajeetPatil/}{Indrajeet Patil}
#' @return A photo of a cat is downloaded and displayed in the plot window.
#'
#' @param meow Logical that decides whether to play a meow sound along with the
#'   picture of a cat.
#' @inheritParams meowR
#'
#' @importFrom rvest html_session html_nodes html_attr
#' @importFrom imager load.image
#' @importFrom purrr map
#' @importFrom tibble as_tibble enframe
#' @importFrom dplyr %>% mutate filter
#' @importFrom stringr str_split str_remove_all
#' @importFrom graphics plot
#'
#' @examples
#' kittyR::kittyR(meow = FALSE)
#' @export

# function body
kittyR <- function(meow = TRUE, sound = 1) {

  # getting all cat images from webpage of interest
  kitties <-
    rvest::html_session(url = "https://pixabay.com/en/photos/cat/") %>%
    rvest::html_nodes(x = ., css = "img")

  # getting static images
  df_static <- kitties %>%
    rvest::html_attr(x = ., name = "src") %>%
    tibble::enframe(x = ., name = "id", value = "url") %>%
    dplyr::filter(.data = ., !stringr::str_detect(url, "static"))

  # getting images with two source files (but retaining only the 480 pixel ones)
  df_srcset <-
    kitties %>%
    rvest::html_attr(x = ., name = "data-lazy-srcset") %>%
    stringr::str_split(
      string = .,
      pattern = ",",
      simplify = FALSE
    ) %>%
    purrr::map(
      .x = .,
      .f = ~ trimws(
        x = stringr::str_remove_all(string = ., pattern = "[1-9]x$"),
        which = "both"
      )
    ) %>%
    purrr::map(.x = ., .f = stats::na.omit) %>%
    unlist(x = .) %>%
    tibble::enframe(x = ., name = "id", value = "url") %>%
    dplyr::filter(.data = ., !grepl("340.jpg$", url))

  # combining both images sets and giving them a unique id
  df_combined <- dplyr::bind_rows(df_static, df_srcset, .id = "image_type") %>%
    dplyr::mutate(.data = ., id = dplyr::row_number(x = url)) %>%
    dplyr::arrange(.data = ., id)

  # create a temporary dierctory
  temporary_file_location <- paste0(tempdir(), "/kitties.png")

  # download a random image
  utils::download.file(
    url = df_combined$url[sample(x = 1:length(df_combined$url), size = 1)],
    destfile = temporary_file_location,
    mode = "wb"
  )

  # bring the kitties to R
  kitty <- imager::load.image(temporary_file_location)

  # if needed, play a meow sound
  if (isTRUE(meow)) {
    kittyR::meowR(sound = sound)
  }

  # display the cat
  graphics::plot(kitty, yaxt = "n", axes = FALSE)
}