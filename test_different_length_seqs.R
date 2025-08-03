source('same_def_matlab_100tree_11mtry_rf.mdl')
return_specific_length_seqs <- function(pn,max_len=30){
	po = pn$po
	ne = pn$ne
	ln = nchar(ne)
	lp = nchar(po)
	nid = which(ln %in% 5:max_len)
	pid = which(lp %in% 5:max_len)
	sp_len_po = po[pid]
	sp_len_ne = ne[nid]
	return(list(po=sp_len_po,ne=sp_len_ne))
}
pn = read_pn()
pn30 = return_specific_length_seqs(pn,max_len=30)
