# Calculate PR curve, PR AUC, ROC curve, and ROC AUC for all or selected classifiers from caret package
#currently caret does not have a function to do this simultaneously

# Install packages
library(caret)
library(pROC)
library(dplyr)
library(earth)
library(PRROC)

# Assuming 'data' is already loaded and preprocessed
data <- read.csv(" ")  #read your dataset

data <- na.omit(data)  #drop NAs

# Convert 'response' to factor with valid class names
data$response <- as.factor(data$response)

# Ensure the factor levels are valid R variable names
levels(data$response) <- make.names(levels(data$response))

# Check the levels to confirm
print(levels(data$response))

#you can edit this based on your cross-validation analysis
#as an example I used dividing data into two pieces based on date
# Split data into train and test sets using 'Date'
data$Date <- as.Date(data$Date, format = "%m/%d/%Y")
cutoff_date <- max(data$Date) - 60

train_data <- data[data$Date < cutoff_date, ]
test_data <- data[data$Date >= cutoff_date, ]

train_features <- train_data %>% select(-c(Date, response))
train_target <- train_data$response

test_features <- test_data %>% select(-c(Date, response))
test_target <- test_data$response

# Define train control for cross-validation
train_control <- trainControl(method = "cv", number = 5, classProbs = TRUE, summaryFunction = twoClassSummary)

# List of 13 selecet models to test
# model_list <- c("rf", "xgbTree", "glm", "svmRadial", "knn", "glmnet", "rpart", "naive_bayes","gbm", "nnet", "pls", "logreg", "lda", "qda", "mars", "earth")

# Get list of ALL available classification models in caret
model_list <- modelLookup()
classification_models <- model_list[model_list$forClass == TRUE, "model"]

# Train multiple models and store the results, with error handling
model_results <- lapply(model_list, function(model_name) {
  tryCatch({
    message("Training model: ", model_name)
    model <- train(train_target ~ ., data = cbind(train_features, train_target), 
                   method = model_name, trControl = train_control, metric = "ROC")
    return(list(model = model, name = model_name))
  }, error = function(e) {
    message("Model failed: ", model_name)
    message("Error: ", e$message)
    return(NULL)
  })
})

# Filter out models that failed during training
model_results <- Filter(Negate(is.null), model_results)

# Evaluate each model on the test set and calculate AUC and PR AUC
predictions <- lapply(model_results, function(model_info) {
  model <- model_info$model
  prob <- predict(model, newdata = test_features, type = "prob")
  
  # Calculate ROC curve and AUC
  roc_curve <- roc(test_target, prob[, 2])
  auc_value <- auc(roc_curve)
  
  # Calculate PR curve and PR AUC
  pr_curve <- pr.curve(scores.class0 = prob[, 2], weights.class0 = as.numeric(test_target == levels(test_target)[2]), curve = FALSE)
  pr_auc_value <- pr_curve$auc.integral
  
  return(list(model_name = model_info$name, auc = auc_value, pr_auc = pr_auc_value))
})

# Convert predictions list to a data frame for ranking
auc_df <- do.call(rbind, lapply(predictions, function(x) data.frame(Model = x$model_name, AUC = x$auc, PR_AUC = x$pr_auc)))

