## Load libraries
library(tidyverse)
library(magrittr)
library(caret)
library(iml)
library(ggplot2)
library(plotly)


## Load model artefacts
VERSION_DATE = "2018-09-30"
OUTPUT = readRDS(sprintf('objects/modeloutput_%s.rds',VERSION_DATE))

model = OUTPUT$model
predictor = OUTPUT$predictor


########################################
  
#* @apiTitle Attrition Risk Scoring API

#* Predict risk of attrition
#* @post /predict
function(...){
  
  postobj = list(...)

  payload = postobj[setdiff(
    names(postobj),
    c('req','res')
  )]
  
  # test dataframe
  testX = data.frame(payload)
  
  # factor variables
  for(col in colnames(testX)){
    if(is.factor(model$trainingData[[col]])){
      testX[[col]] = factor(
        x = testX[[col]],
        levels = levels(model$trainingData[[col]])
      )
    }
  }
  
  
  prediction = predict(model,testX,type = 'prob')
  risk_score = prediction$Yes
  
  lime_explain = LocalModel$new(
    predictor = predictor,
    x.interest = testX,
    k = 5
  )
  
  lime_explain_results = lime_explain$results %>%
    filter(.class == 'Yes')
  
  return(list(
    risk_score = prediction,
    lime_features = lime_explain_results
  ))
  
}

#* Show top LIME features
#* @param k Top k variables from LIME
#* @serializer htmlwidget
#* @post /lime/<k>
function(k,...){
  
  postobj = list(...)
  
  payload = postobj[setdiff(
    names(postobj),
    c('req','res')
  )]
  
  # test dataframe
  testX = data.frame(payload)
  
  # factor variables
  for(col in colnames(testX)){
    if(is.factor(model$trainingData[[col]])){
      testX[[col]] = factor(
        x = testX[[col]],
        levels = levels(model$trainingData[[col]])
      )
    }
  }
  
  
  prediction = predict(model,testX,type = 'prob')
  risk_score = prediction$Yes
  
  lime_explain = LocalModel$new(
    predictor = predictor,
    x.interest = testX,
    k = as.numeric(k)
  )
  

  
  lime_explain_results = lime_explain$results %>%
    filter(.class == 'Yes')
  
  cat(str(lime_explain_results))
  
  p = lime_explain_results %>%
    ggplot(aes(
      x=feature.value,
      y=effect,
      fill=(effect>0)
    )) +
    geom_col(show.legend = FALSE) +
    coord_flip() +
    theme_bw() +
    scale_fill_manual(values=c('lightgreen','red')) +
    ggtitle(sprintf('Probability of Attrition : %.3f',risk_score))
  
  ggplotly(p)
  
}