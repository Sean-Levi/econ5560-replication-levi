library(readxl)
library(stats)

# Create the outputs and logs folders if missing.
dir.create("outputs", showWarnings = FALSE)
dir.create("logs", showWarnings = FALSE)

#########################################
# Modeling assumptions and choices
#########################################

# 1. Used a pooled Tobit model without individual random effects.
# 2. Created dummy variables from the plant codes because a dictionary
#    identifying the specific plant types was not provided.
# 3. Calculated WTP standard errors using the delta method.
# 4. Calculated two-sided normal z-test p-values and assigned
#    statistical significance stars.
# 5. Excluded missing att_importance responses from the
#    labeling-importance subgroups.

spa <- as.data.frame(read_excel("data/SPA_combined_sample.xls"))

# Treat plant type as categorical, with the first level as the reference.
plant_controls <- model.matrix(~ factor(plant), spa)[, -1, drop = FALSE]
colnames(plant_controls) <- paste0("plant_code_", levels(factor(spa$plant))[-1])

spa <- cbind(spa, plant_controls)


# Label attributes.
Label_columns <- c(
  "neonic_text",
  "neonic_logo",
  "neonic_treat"
)

# Explanatory variables.
Model_columns <- c(
  Label_columns,
  "bio_pot", # Biodegradable container.
  colnames(plant_controls)
)

# Display labels for Table 6.
Diplay_labels <- c(
  "Neonicotinoid-free text label",
  "Neonicotinoid-free logo",
  "Neonicotinoid-treated text label"
)

#########################################
# Tobit estimation
#########################################

tobit_results <- function(data) {
  X <- cbind(
    1, # Intercept.
    as.matrix(data[Model_columns])
  )
  
  bid <- as.numeric(data$bid)
  zero_bid <- bid == 0
  
  # Pooled Tobit specification: bid = max(0, X beta + u).
  negative_log_likelihood <- function(theta) {
    beta <- theta[-length(theta)]
    sigma <- exp(theta[length(theta)]) # Ensures sigma is positive.
    xb <- drop(X %*% beta)
    
    # Negative log-likelihood contribution from zero bids.
    zero_part <- -sum(pnorm(-xb[zero_bid] / sigma, log.p = TRUE))
    
    # Contribution from positive bids, using the normal density.
    # AI assistance was used to assemble this calculation.
    positive_part <- sum(
      0.5 * ((bid[!zero_bid] - xb[!zero_bid]) / sigma)^2 +
        log(sigma) + 0.5 * log(2 * pi)
    )
    
    zero_part + positive_part
  }
  
  # Use OLS on positive bids to obtain starting coefficient values.
  start_beta <- coef(lm.fit(
    X[!zero_bid, , drop = FALSE],
    bid[!zero_bid]
  ))
  
  # Minimize the negative log-likelihood using BFGS.
  fit <- optim(
    c(start_beta, 0),
    negative_log_likelihood,
    method = "BFGS",
    hessian = TRUE
  )
  
  theta <- fit$par
  
  # Approximate the parameter covariance matrix using the inverse Hessian.
  covariance <- solve(fit$hessian)
  
  #########################################
  # WTP estimates and standard errors
  #########################################
  
  wtp <- function(theta, k) {
    beta <- theta[-length(theta)]
    sigma <- exp(theta[length(theta)])
    mean(pnorm(drop(X %*% beta) / sigma) * beta[k])
  }
  
  results <- list()
  
  # The first three coefficients after the intercept represent the labels.
  for (k in 2:4) {
    estimate <- wtp(theta, k)
    
    # Approximate the gradient numerically for delta-method standard errors.
    gradient <- numeric(length(theta))
    
    for (j in seq_along(theta)) {
      change <- numeric(length(theta))
      change[j] <- 1e-5
      
      gradient[j] <- (
        wtp(theta + change, k) -
          wtp(theta - change, k)
      ) / (2e-5)
    }
    
    se <- sqrt(max(drop(t(gradient) %*% covariance %*% gradient), 0))
    
    # Two-sided normal z-test.
    p_value <- 2 * pnorm(-abs(estimate / se))
    
    # Assign statistical significance stars.
    if (p_value < 0.001) {
      stars <- "***"
    } else if (p_value < 0.01) {
      stars <- "**"
    } else if (p_value < 0.05) {
      stars <- "*"
    } else {
      stars <- ""
    }
    
    results[[k-1]] <- c(estimate, stars, se)
  }
  
  results
}

#########################################
# Table creation
#########################################

groups <- list(
  "Sample Total" = spa,
  "Attitude toward pollinator: Agree Group" = spa[spa$att_polen == 1, ],
  "Attitude toward pollinator: Disagree Group" = spa[spa$att_polen == 0, ],
  "Attitude toward neonicotinoid regulation: Agree Group" = spa[spa$att_regulation == 1, ],
  "Attitude toward neonicotinoid regulation: Disagree Group" = spa[spa$att_regulation == 0, ],
  "Attitude toward labeling importance: Important Group" = spa[!is.na(spa$att_importance) & spa$att_importance == 1, ],
  "Attitude toward labeling importance: Unimportant Group" = spa[!is.na(spa$att_importance) & spa$att_importance == 0, ],
  "Overall PEB attitude: PEB Group" = spa[spa$att_overall == 1, ],
  "Overall PEB attitude: Non-PEB Group" = spa[spa$att_overall == 0, ]
)

rows <- list()

for (group_name in names(groups)) {
  group_data <- groups[[group_name]]
  rows[[length(rows) + 1]] <- c(group_name, "", "", "")
  
  for (i in seq_along(Diplay_labels)) {
    rows[[length(rows) + 1]] <- c(Diplay_labels[i], tobit_results(group_data)[[i]])
  }
}

tobit_table6 <- as.data.frame(
  do.call(rbind, rows),
  stringsAsFactors = FALSE
)

colnames(tobit_table6) <- c(
  "Experimental Auction / Tobit",
  "WTP Mean",
  "Significance",
  "SE"
)

for (column in c("WTP Mean", "SE")) {
  values <- suppressWarnings(as.numeric(tobit_table6[[column]]))
  tobit_table6[[column]] <- ifelse(
    is.na(values), "", format(round(values, 3), nsmall = 3)
  )
}

write.csv(
  tobit_table6,
  "outputs/table6.csv",
  row.names = FALSE
)

print(sessionInfo())