#source('random_forest_10cv_amp5_30.R')
require(seqinr)
require(caret)
require(protr)
require(MLmetrics)
require(ggplot2)
require(randomForest)
library("ROCR")
library("pROC")
library('PRROC')
library(psych)

constructDescMatrix <- function(seqs, lambda=4, method='AAC',class_label=1) {
    #cat(method,'\n')
    seqs_n <- length(seqs)
	data=NULL
	if ('APAAC' %in% method){
		temp=NULL
		for (i in 1:seqs_n) {
			T=NULL
           		if (length(seqs[i]) <= lambda){l <- nchar(seqs[i])-1} else{l <- lambda}
            		t=extractAPAAC(seqs[i],lambda=l,w=0.07)
			T=c(T,t)
			temp=rbind(temp,T)
			rownames(temp)[i]=i
		}
		data=cbind(data,temp)
	}
	if ('PAAC' %in% method){
		temp=NULL
		for (i in 1:seqs_n) {
			T=NULL
            		if (length(seqs[i]) <= lambda){l <- nchar(seqs[i])-1} else{l <- lambda}
			t=extractPAAC(seqs[i],lambda=l,w=0.07)
			T=c(T,t)
			temp=rbind(temp,T)
			rownames(temp)[i]=i
		}
		data=cbind(data,temp)
	}
	if ('C' %in% method){
		temp=NULL
		for (i in 1:seqs_n) {
			T=NULL
			t=extractCTDC(seqs[i])
			T=c(T,t)
			temp=rbind(temp,T)
			rownames(temp)[i]=i
		}
		data=cbind(data,temp)
	}
	if ('T' %in% method){
		temp=NULL
		for (i in 1:seqs_n) {
			T=NULL
			t=extractCTDT(seqs[i])
			T=c(T,t)
			temp=rbind(temp,T)
			rownames(temp)[i]=i
		}
		data=cbind(data,temp)
	}
	if ('D' %in% method){
		temp=NULL
		for (i in 1:seqs_n) {
			T=NULL
			t=extractCTDD(seqs[i])
			
			T=c(T,t)
			temp=rbind(temp,T)
			rownames(temp)[i]=i
		}
		data=cbind(data,temp)
	}
	if ('AAC' %in% method){
		temp=NULL
		for (i in 1:seqs_n) {
			T=NULL
			t=extractAAC(seqs[i])
			T=c(T,t)
			temp=rbind(temp,T)
			rownames(temp)[i]=i
		}
		data=cbind(data,temp)
	}

    data=as.data.frame(data)

    Data=data.frame(data)
    if (!is.null(class_label)){
        class <- rep(class_label,seqs_n)
        Data <- cbind(Data,class)
    }

    cat("Dimension of DescMatrix: ", dim(Data),"\n")

    return(Data)

}
################ generate ne_po features #################
gene_ftdata <- function(pn_seqs,ft='D'){
    po=pn_seqs$po
    ne=pn_seqs$ne
    pdata=constructDescMatrix(po,4,ft)
    ndata=constructDescMatrix(ne,4,ft,class_label=0)
    data<-rbind(pdata,ndata)
    rownames(data)<-c(1:nrow(data))
    return(data)
}
develop_mdl <- function(p.path='./trian_po_set3298_for_ampep_sever.fasta',n.path='./trian_ne_set9894_for_ampep_sever.fasta'){
	pn=read_pn(p.path,n.path)
	data=gene_ftdata(pn)
	rf=rf_yan(data,test_data=data[1:10,])
	saveRDS(rf$mdl,'./same_def_matlab_100tree_11mtry_rf.mdl')
}
#################### train model #########################
rf_yan <- function(data=data_d,data_rest=NULL,mtry=11,ntree=100,test_data=NULL,def=F){
	col=ncol(data)
	data$class=factor(data$class)
	if (!is.null(data_rest)) {data_rest$class=factor(data_rest$class)}
	flds <- createFolds(data$class, k = 10, list = TRUE, returnTrain = FALSE)
	pre=NULL
	ori=NULL
	if (is.null(test_data)){	
		for (i in 1:10){
			train=data[-flds[[i]],] 
			test=data[flds[[i]],]
			if (def){
				rf <- randomForest(class ~., rbind(train,data_rest),ntree=100,proximity=TRUE)
			}else{ 
				rf <- randomForest(class ~., rbind(train,data_rest),proximity=TRUE,mtry=mtry,ntree=ntree)
			}
			prediction=predict(rf,test[,-col],type='prob')
			pre=c(pre,prediction[,2])
			ori=c(ori,(test[,col]))		
		}
		ori=ori-1
	} else{
		if (def){
			rf <- randomForest(class ~., rbind(data,data_rest),ntree=100,proximity=TRUE)
		}else{ 
			rf <- randomForest(class ~., rbind(data,data_rest),proximity=TRUE,mtry=mtry,ntree=ntree)
		}
		if (ncol(test_data)==col){
			prediction=predict(rf,test_data[,-col],type='prob')
			ori=test_data[,col]
		} else{
			prediction=predict(rf,test_data,type='prob')
		}
		pre=prediction[,2]
	}	
	return(list(mdl=rf,sco=pre,ori=ori))
}

################ generate ne_po features #################
read_pn <- function(active_name='AMP_classify.fasta',unactive_name='nonamp3timesamp.fasta'){
    protdata = read.fasta(active_name,seqtype="AA",as.string=TRUE)
    active_seqs = unlist(getSequence(protdata,as.string=TRUE),recursive=FALSE)
    po <- unlist(active_seqs)
    protdata = read.fasta(unactive_name,seqtype="AA",as.string=TRUE)
    active_seqs = unlist(getSequence(protdata,as.string=TRUE),recursive=FALSE)
    ne <- unlist(active_seqs)
    return(list(po=po,ne=ne))
}
args = commandArgs(trailingOnly=TRUE)
# get the input data which is from the website
test_fasta=read.fasta(args[1],seqtype="AA",as.string=TRUE)
seq_name=getName(test_fasta)
test_seq=unlist(unlist(getSequence(test_fasta,as.string=TRUE),recursive=FALSE))
test_d=constructDescMatrix(test_seq,4,'D',class_label=NULL)

#load random forest training model
model = readRDS('./same_def_matlab_100tree_11mtry_rf.mdl')
test_prob <- predict(model, newdata = test_d, type = "vote")
class=rep('1',nrow(test_prob))
class[which(test_prob[,2]<0.5)]='0'
prob=data.frame(seq_name,class,'AMP_probablity'=sprintf("%1.6f",test_prob[,2]))
#result = cbind.data.frame(output_data[[1]],prediction,sprintf("%1.6f",output_data[[3]]))


write.table(prob, args[2], sep=" ",col.names = F, row.names = F, quote = FALSE)
