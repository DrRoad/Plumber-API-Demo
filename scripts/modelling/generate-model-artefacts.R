## Reference : https://www.business-science.io/business/2018/06/25/lime-local-feature-interpretation.html

## Load libraries
library(rsample)
library(tidyverse)
library(magrittr)
library(caret)
library(iml)

## Load data
DATA = rsample::attrition %>%
  mutate_if(is.ordered,factor,ordered=FALSE) %>%
  mutate(Attrition = factor(Attrition, levels=c('Yes','No')))


## Modelling to predict if employee will resign or not
set.seed(12345)
idx = createDataPartition(
  DATA$Attrition,
  p = 0.7,
  list = FALSE,
  times = 1
)

trainDATA = DATA %>% slice(idx)
testDATA = DATA %>% slice(-idx) 

fit_control = trainControl(
  method = 'repeatedcv',
  number = 5,
  repeats = 1
)

model = train(
  Attrition ~ . ,
  data = trainDATA,
  method = 'rf',
  preProcess = c('scale','center'),
  trControl = fit_control,
  verbose = FALSE
)

## LIME Model to explain LDA model
trainX = trainDATA %>%
  select(-Attrition) %>%
  as.data.frame

predictor = Predictor$new(
  model = model,
  data = trainX,
  y = trainX$Attrition
)

## Test LIME Model
testX = testDATA %>%
  select(-Attrition) %>%
  as.data.frame %>%
  slice(2)

prediction = predict(model,testX,type = 'prob')

lime_explain = LocalModel$new(
  predictor = predictor,
  x.interest = testX,
  k = 5
)

lime_explain$results %>%
  filter(.class == 'Yes') %>%
  ggplot(aes(
    x=feature.value,
    y=effect,
    fill=(effect>0)
  )) +
  geom_col(show.legend = FALSE) +
  coord_flip() +
  theme_bw() +
  scale_fill_manual(values=c('lightgreen','red')) +
  ggtitle(sprintf('Probability of Attrition : %.3f',prediction$Yes))

################################################################

## Save model artefacts

OUTPUT = list()
OUTPUT$model = model
OUTPUT$predictor = predictor

saveRDS(OUTPUT,sprintf('objects/modeloutput_%s.rds',Sys.Date()))


## Save sample new data
testX %>%
  as.data.frame %>%
  dplyr::slice(1) %>% 
  jsonlite::toJSON(pretty = TRUE) %>%
  as.character %>% 
  str_replace_all('(\\[|\\])','') %>%
  str_trim %>%
  cat(file='objects/testinput.json')

