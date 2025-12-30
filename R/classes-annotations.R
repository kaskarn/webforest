# Annotation S7 classes for webforest

#' ReferenceLine: Vertical reference line annotation
#'
#' @param x X-axis position for the line
#' @param label Optional label for the line
#' @param style Line style: "solid", "dashed", "dotted"
#' @param color Line color (optional, uses theme default)
#'
#' @export
ReferenceLine <- new_class(
  "ReferenceLine",
  properties = list(
    x = class_numeric,
    label = new_property(class_character, default = NA_character_),
    style = new_property(class_character, default = "dashed"),
    color = new_property(class_character, default = NA_character_)
  ),
  validator = function(self) {
    if (!self@style %in% c("solid", "dashed", "dotted")) {
      return("style must be 'solid', 'dashed', or 'dotted'")
    }
    NULL
  }
)

#' Create a reference line annotation
#'
#' @param x X-axis position
#' @param label Optional label
#' @param style Line style
#' @param color Line color
#'
#' @return A ReferenceLine object
#' @export
forest_refline <- function(
    x,
    label = NULL,
    style = c("dashed", "solid", "dotted"),
    color = NULL) {
  style <- match.arg(style)

  ReferenceLine(
    x = x,
    label = label %||% NA_character_,
    style = style,
    color = color %||% NA_character_
  )
}

#' RiskOfBiasAssessment: Risk of bias for a single study
#'
#' @param study_id Study identifier
#' @param assessments Named list of domain -> rating ("low", "unclear", "high")
#'
#' @export
RiskOfBiasAssessment <- new_class(
  "RiskOfBiasAssessment",
  properties = list(
    study_id = class_character,
    assessments = class_list
  ),
  validator = function(self) {
    valid_ratings <- c("low", "unclear", "high")
    for (rating in self@assessments) {
      if (!rating %in% valid_ratings) {
        return(paste(
          "All assessments must be one of:",
          paste(valid_ratings, collapse = ", ")
        ))
      }
    }
    NULL
  }
)

#' RiskOfBias: Risk of bias traffic light annotation
#'
#' @param domains Character vector of domain names
#' @param assessments List of RiskOfBiasAssessment objects
#'
#' @export
RiskOfBias <- new_class(
  "RiskOfBias",
  properties = list(
    domains = class_character,
    assessments = class_list
  )
)

#' Create a risk of bias annotation
#'
#' @param data Data frame with study_id and domain columns
#' @param study_id Column name for study IDs
#' @param ... Domain columns (unquoted)
#'
#' @return A RiskOfBias object
#' @export
forest_rob <- function(data, study_id = "study_id", ...) {
  # This is a simplified version - full implementation would use tidyselect
  domains <- names(data)[!names(data) %in% study_id]

  assessments <- lapply(seq_len(nrow(data)), function(i) {
    row <- data[i, ]
    RiskOfBiasAssessment(
      study_id = as.character(row[[study_id]]),
      assessments = as.list(row[domains])
    )
  })

  RiskOfBias(
    domains = domains,
    assessments = assessments
  )
}

#' CustomAnnotation: Custom shape annotation
#'
#' @param study_id Study to annotate
#' @param shape Shape type: "circle", "square", "triangle", "star"
#' @param position Position relative to point: "before", "after", "overlay"
#' @param color Shape color
#' @param size Shape size multiplier
#'
#' @export
CustomAnnotation <- new_class(
  "CustomAnnotation",
  properties = list(
    study_id = class_character,
    shape = new_property(class_character, default = "circle"),
    position = new_property(class_character, default = "after"),
    color = new_property(class_character, default = "#8b5cf6"),
    size = new_property(class_numeric, default = 1.0)
  ),
  validator = function(self) {
    if (!self@shape %in% c("circle", "square", "triangle", "star")) {
      return("shape must be 'circle', 'square', 'triangle', or 'star'")
    }
    if (!self@position %in% c("before", "after", "overlay")) {
      return("position must be 'before', 'after', or 'overlay'")
    }
    NULL
  }
)

#' Create a custom annotation
#'
#' @param study_id Study to annotate
#' @param shape Shape type
#' @param position Position
#' @param color Color
#' @param size Size multiplier
#'
#' @return A CustomAnnotation object
#' @export
forest_annotation <- function(
    study_id,
    shape = c("circle", "square", "triangle", "star"),
    position = c("after", "before", "overlay"),
    color = "#8b5cf6",
    size = 1.0) {
  shape <- match.arg(shape)
  position <- match.arg(position)

  CustomAnnotation(
    study_id = study_id,
    shape = shape,
    position = position,
    color = color,
    size = size
  )
}
