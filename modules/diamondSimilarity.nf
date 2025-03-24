#!/usr/bin/env nextflow
nextflow.enable.dsl=2

process createDatabase {
  container = 'veupathdb/diamondsimilarity:v1.0.0'

  input:
    path fasta
    val dbname

  output:
  path "${dbname}.dmnd"

  script:
  """
  filename=$fasta
  filename_without_suffix="\${filename%.gz}"
  if [[ "$fasta" == *.gz ]]; then
    gunzip -d -k --force $fasta
  fi
  diamond makedb --in \$filename_without_suffix --db $dbname
  """
}

process diamondSimilarity {
  container = 'veupathdb/diamondsimilarity:v1.0.0'

  input:
    path queryFasta
    path database

  output:
    path 'diamondSimilarity.out', emit: output_file

  script:
   """
   diamond $params.blastProgram \
    -d $database \
    -q $queryFasta \
    -o diamondSimilarity.out \
    ${task.ext.args}
   """
}

process gzip {
  container = 'veupathdb/diamondsimilarity:v1.0.0'

  publishDir params.outputDir, mode: 'copy'

  input:
  path similarities
  val outputFileName

  output:
  path "${outputFileName}.gz"

  script:
   """
   gzip -c $similarities >${outputFileName}.gz
   """
}



workflow nonConfiguredDatabase {
  take:
    seqs

  main:
    database = createDatabase(params.targetFastaFile, "targetdb")

    preConfiguredDatabase(seqs, database)
}

workflow preConfiguredDatabase {
  take:
    seqs
    database

  main:
  sims = diamondSimilarityResults = diamondSimilarity(seqs, database)
  gzip(sims.output_file.collectFile(), params.outputFile)

}
