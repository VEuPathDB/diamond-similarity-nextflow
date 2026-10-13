#!/usr/bin/env nextflow
nextflow.enable.dsl=2

//---------------------------------------------------------------
// Param Checking 
//---------------------------------------------------------------

//--------------------------------------------------------------------------
// Includes
//--------------------------------------------------------------------------

include { nonConfiguredDatabase } from './modules/diamondSimilarity.nf'
include { preConfiguredDatabase } from './modules/diamondSimilarity.nf'

//--------------------------------------------------------------------------
// Main Workflow
//--------------------------------------------------------------------------

workflow {
  if(params.queryFastaFile) {
    seqs = channel.fromPath( params.queryFastaFile ).splitFasta( by:params.fastaSubsetSize, file:true  )
  }
  else {
    error "Missing params.queryFastaFile"
  }

  if (params.preConfiguredDatabase) {
    if (!params.database) {
      error "Missing params.database"
    }
  }

  if (params.preConfiguredDatabase) {
    preConfiguredDatabase(seqs, params.targetDatabaseIndex)
  }
  else {
    nonConfiguredDatabase(seqs)
  }

}

