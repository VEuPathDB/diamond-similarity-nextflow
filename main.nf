#!/usr/bin/env nextflow
nextflow.enable.dsl=2

//---------------------------------------------------------------
// Param Checking 
//---------------------------------------------------------------

if(params.queryFastaFile) {
  seqs = Channel.fromPath( params.queryFastaFile ).splitFasta( by:params.fastaSubsetSize, file:true  )
}
else {
  throw new Exception("Missing params.queryFastaFile")
}

if (params.preConfiguredDatabase) {
  if (!params.database) {
    throw new Exception("Missing params.database")
  }
}

//--------------------------------------------------------------------------
// Includes
//--------------------------------------------------------------------------

include { nonConfiguredDatabase } from './modules/diamondSimilarity.nf'
include { preConfiguredDatabase } from './modules/diamondSimilarity.nf'

//--------------------------------------------------------------------------
// Main Workflow
//--------------------------------------------------------------------------

workflow {
  if (params.preConfiguredDatabase) {
    preConfiguredDatabase(seqs, params.targetDatabaseIndex)
  }
  else {
    nonConfiguredDatabase(seqs)
  }

}

