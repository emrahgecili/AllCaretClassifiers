# caretClassifyHub
Runs ALL/ Multiple Caret Classifiers Concurrently

This function simultaneously trains and evaluates multiple classification models from the caret package, providing comprehensive performance metrics, including Precision-Recall (PR) curve, PR AUC, Receiver Operating Characteristic (ROC) curve, and ROC AUC for each model. It allows users to run all available classifiers or a specified subset, streamlining model comparison within a single execution.

While the caret package supports individual model training, it currently lacks functionality to execute multiple classifiers concurrently in R, making this simple function a quick solution for parallel model evaluation.
