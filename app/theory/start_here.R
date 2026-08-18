start_here_step <- function(number, title, description, outcome, icon) {
  shiny::tags$article(
    class = "start-step",
    shiny::div(
      class = "start-step-marker",
      shiny::span(class = "start-step-number", number),
      bsicons::bs_icon(icon)
    ),
    shiny::div(
      class = "start-step-copy",
      shiny::h3(title),
      shiny::p(description),
      shiny::div(
        class = "start-step-outcome",
        shiny::strong("What you obtain"),
        shiny::span(outcome)
      )
    )
  )
}

start_here_term <- function(term, explanation) {
  shiny::div(
    class = "start-term",
    shiny::tags$dt(term),
    shiny::tags$dd(explanation)
  )
}

build_start_here_content <- function() {
  shiny::div(
    class = "start-here-page",
    shiny::tags$section(
      class = "start-here-hero",
      shiny::div(
        class = "start-here-eyebrow",
        bsicons::bs_icon("compass"),
        "START HERE"
      ),
      shiny::h2("Learn how the benchmark defines ‘similar’ load profiles"),
      shiny::p(
        class = "start-here-lead",
        paste0(
          "This app does not search for a universally best clustering algorithm. ",
          "It compares different definitions of similarity for the same accepted electricity ",
          "profiles. A result changes when you change the calendar representation, ",
          "normalization, distance, clustering rule or number of groups, so each choice ",
          "must be understood before the final score is interpreted."
        )
      ),
      shiny::div(
        class = "start-here-purpose",
        shiny::div(
          shiny::strong("The starting point"),
          shiny::span("One complete year of hourly readings for each profile.")
        ),
        shiny::div(
          shiny::strong("The final result"),
          shiny::span(paste0(
            "Groups of similar annual load profiles, representative curves and ",
            "validation results that show whether the grouping is coherent and useful."
          ))
        )
      )
    ),
    shiny::tags$section(
      class = "start-here-section",
      shiny::div(
        class = "start-section-heading",
        shiny::span("THE WORKFLOW"),
        shiny::h2("Four steps, each with a clear purpose"),
        shiny::p(
          paste0(
            "The main navigation follows the order in which a study should be carried ",
            "out. You can return to an earlier step without losing completed results."
          )
        )
      ),
      shiny::div(
        class = "start-workflow",
        start_here_step(
          "01",
          "Prepare and inspect the data",
          paste0(
            "Choose the included demonstration or upload your own curves. The app checks ",
            "dates, missing hours, duplicated timestamps, negative values and whether each ",
            "profile covers a complete calendar year. You can then inspect the accepted ",
            "curves before any model is fitted."
          ),
          "A clean and comparable set of hourly profiles.",
          "database-check"
        ),
        start_here_step(
          "02",
          "Design one or more experiments",
          paste0(
            "An experiment is one complete set of choices for grouping the profiles. ",
            "You decide which hourly pattern to retain, whether annual demand magnitude ",
            "matters, whether the data are compressed, how two profiles are compared and ",
            "which clustering method forms the groups."
          ),
          "A queue of clearly defined candidate clustering methods.",
          "diagram-3"
        ),
        start_here_step(
          "03",
          "Run and compare",
          paste0(
            "The app fits the queued experiments to the same accepted profiles. Model ",
            "selection compares separation, repeatability, cluster sizes, runtime and ",
            "other quality indicators. The recommendation highlights the strongest ",
            "eligible result, while keeping every candidate available for review."
          ),
          "A transparent comparison and a recommended candidate.",
          "bar-chart-line"
        ),
        start_here_step(
          "04",
          "Understand the selected result",
          paste0(
            "In Analyse results, representative profiles show what the chosen groups mean ",
            "in time. You can also inspect ",
            "the spread of member curves, annual heatmaps, group sizes, unusual profiles ",
            "and method-specific diagnostics. You can select another fitted method and ",
            "compare how the interpretation changes."
          ),
          "A traceable interpretation that can be exported and communicated.",
          "search"
        )
      )
    ),
    shiny::tags$section(
      class = "start-here-section start-concepts-section",
      shiny::div(
        class = "start-section-heading",
        shiny::span("PLAIN-LANGUAGE GUIDE"),
        shiny::h2("The few ideas you need before starting"),
        shiny::p(paste0(
          "These terms appear throughout the application and have precise but ",
          "approachable meanings."
        ))
      ),
      shiny::tags$dl(
        class = "start-terms-grid",
        start_here_term(
          "Electricity profile or curve",
          paste0(
            "The sequence of hourly consumption values belonging to one meter, home, ",
            "building or piece of equipment. In this study, one profile represents one ",
            "complete calendar year."
          )
        ),
        start_here_term(
          "Experiment",
          paste0(
            "One specific combination of preparation choices and a clustering method. ",
            "Running several experiments lets you compare alternatives fairly instead ",
            "of trusting the first result."
          )
        ),
        start_here_term(
          "Representation",
          paste0(
            "The numerical description of each annual curve that the model actually ",
            "compares. It may retain all hours, summarize a typical week or describe ",
            "behaviour through a smaller set of features."
          )
        ),
        start_here_term(
          "Distance or similarity",
          paste0(
            "The rule used to decide whether two profiles are close. Some rules compare ",
            "the same hours directly; others tolerate small shifts in the timing of a peak."
          )
        ),
        start_here_term(
          "Clustering method",
          paste0(
            "The procedure that forms groups from the prepared numerical profiles. ",
            "Different methods make different assumptions about group shape, density ",
            "and the treatment of unusual profiles."
          )
        ),
        start_here_term(
          "Cluster and interpretation profile",
          paste0(
            "A cluster is a set of profiles judged to be similar under the selected ",
            "configuration. The common weekly interpretation profile summarizes member ",
            "curves for comparison; it is not necessarily the prototype fitted by the algorithm."
          )
        ),
        start_here_term(
          "Benchmark",
          paste0(
            "The controlled comparison of all queued experiments. Every candidate uses ",
            "the same accepted data so differences can be attributed to the modelling ",
            "choices rather than to a different sample."
          )
        ),
        start_here_term(
          "Recommended model",
          paste0(
            "The candidate ranked first after eligibility gates and run-relative scaling. ",
            "It is a transparent inspection priority, not an unquestionable answer."
          )
        )
      )
    ),
    shiny::tags$section(
      class = "start-here-section controlled-benchmark-section",
      shiny::div(
        class = "start-section-heading",
        shiny::span("CONTROLLED COMPARISONS"),
        shiny::h2("A benchmark is useful only when comparisons are controlled"),
        shiny::p(paste0(
          "Change as few layers as possible when you want to learn why a result changed. ",
          "For example, PAM + Euclidean versus PAM + DTW isolates the distance choice more ",
          "cleanly than changing the representation, distance and algorithm at the same time. ",
          "A broad benchmark can screen heterogeneous candidates, but scientific conclusions ",
          "about a method should come from matched comparisons."
        ))
      )
    ),
    shiny::tags$section(
      class = "start-here-section start-reading-section",
      shiny::div(
        class = "start-section-heading",
        shiny::span("HOW TO READ THE RESULT"),
        shiny::h2("A good score does not prove that a cluster is useful"),
        shiny::p(
          paste0(
            "Clustering has no answer key. The application therefore combines numerical ",
            "checks with visual inspection instead of presenting one metric as the truth."
          )
        )
      ),
      shiny::div(
        class = "start-reading-grid",
        shiny::div(
          class = "start-reading-card",
          bsicons::bs_icon("check2-circle"),
          shiny::h3("Look for agreement across several checks"),
          shiny::p(
            paste0(
              "Prefer groups that are reasonably separated, remain similar when the ",
              "analysis is repeated and contain enough profiles to be useful."
            )
          )
        ),
        shiny::div(
          class = "start-reading-card",
          bsicons::bs_icon("eye"),
          shiny::h3("Return to the original curves"),
          shiny::p(
            paste0(
              "Check whether representative profiles and their members tell a coherent ",
              "electricity-use story. A mathematically neat group may still lack practical meaning."
            )
          )
        ),
        shiny::div(
          class = "start-reading-card",
          bsicons::bs_icon("arrow-repeat"),
          shiny::h3("Compare, then refine"),
          shiny::p(
            paste0(
              "Use the benchmark to identify promising choices, inspect the selected ",
              "model and return to Design experiments when a different question needs testing."
            )
          )
        )
      )
    ),
    shiny::tags$section(
      class = "start-here-next",
      shiny::div(
        shiny::span("READY TO BEGIN"),
        shiny::h2("Start by preparing the data, not by choosing an algorithm"),
        shiny::p(
          paste0(
            "Confirm that the curves are complete and credible first. Then open Design ",
            "experiments to decide what kind of similarity answers your question. The other ",
            "tabs in Learn methods explain every configurable choice in greater depth."
          )
        )
      ),
      bsicons::bs_icon("arrow-right-circle")
    )
  )
}

theory_start_here_ui <- function() {
  bslib::nav_panel(
    "Start here",
    shiny::div(
      class = "theory-explorer theory-start-explorer",
      shiny::tags$aside(
        class = "theory-browser",
        shiny::div(
          class = "theory-browser-heading",
          shiny::span("CATALOGUE"),
          shiny::strong("Start here")
        ),
        shiny::div(
          class = "theory-option-scroll",
          shiny::radioButtons(
            "learn_foundations_item",
            NULL,
            choices = c("How to use this app — Introduction" = "welcome"),
            selected = "welcome"
          )
        )
      ),
      shiny::tags$main(
        class = "theory-detail-pane theory-start-here",
        build_start_here_content()
      )
    )
  )
}
