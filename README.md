# diamond-similarity-nextflow

A Nextflow pipeline that computes protein similarity between a query FASTA file and a target database using [DIAMOND](https://github.com/bbuchfink/diamond).

## Overview

This pipeline runs DIAMOND BLAST-style sequence comparisons (`blastp`/`blastx`, etc.) between a set of query sequences and a target protein database, producing tabular similarity results. It is used within VEuPathDB's genomic data workflows to generate pairwise sequence similarity data — for example, as an input to downstream orthology and comparative genomics pipelines (such as OrthoMCL group building) — using DIAMOND as a faster alternative to traditional BLAST.

The query FASTA is split into subsets and searched in parallel against the target database, and the per-subset results are merged and compressed into a single output file.

## Requirements

- [Nextflow](https://www.nextflow.io/) (DSL2)
- Docker or Singularity/Apptainer (the pipeline runs inside the `veupathdb/diamondsimilarity` container image; select the container engine via the `docker` or `singularity` profile/config in `conf/`)

## Usage

```
nextflow run VEuPathDB/diamond-similarity-nextflow -r main \
  --queryFastaFile /path/to/query.fasta \
  --targetFastaFile /path/to/target.fasta \
  --outputDir /path/to/output \
  -C conf/docker.config \
  -resume
```

The pipeline has a single entry point that branches internally based on `params.preConfiguredDatabase`:

- If `params.preConfiguredDatabase` is `false` (the default), a DIAMOND database is built from `params.targetFastaFile` before running the search.
- If `params.preConfiguredDatabase` is `true`, the search runs directly against an existing DIAMOND database index given by `params.targetDatabaseIndex`, skipping the database-build step.

Example using a pre-built database:

```
nextflow run VEuPathDB/diamond-similarity-nextflow -r main \
  --queryFastaFile /path/to/query.fasta \
  --preConfiguredDatabase true \
  --targetDatabaseIndex /path/to/database.dmnd \
  --outputDir /path/to/output \
  -C conf/docker.config \
  -resume
```

## Key Parameters

| Parameter | Default | Description |
|---|---|---|
| `queryFastaFile` | `data/pcynB/AnnotatedProteins.fsa` | FASTA file of query sequences to search |
| `fastaSubsetSize` | `2000` | Number of sequences per chunk when splitting the query FASTA for parallel searches |
| `blastProgram` | `blastp` | DIAMOND search mode (e.g. `blastp`, `blastx`) |
| `targetFastaFile` | `data/pdb.fsa` | FASTA file used to build the DIAMOND database when `preConfiguredDatabase` is `false` |
| `preConfiguredDatabase` | `false` | Whether to search against an existing DIAMOND database instead of building one |
| `targetDatabaseIndex` | `$launchDir/data/newdb.dmnd` | Path to a pre-built DIAMOND database (`.dmnd`), used when `preConfiguredDatabase` is `true` |
| `outputFile` | `blastSimilarity.out` | Base name of the merged similarity results file |
| `outputDir` | `$launchDir/output` | Directory the final compressed results are published to |

Search sensitivity and formatting options are set in `nextflow.config` via `process.withName:diamondSimilarity.ext.args` (currently `--evalue 0.00001 --masking seg --max-target-seqs 20 --sensitive --comp-based-stats 0 -f 6`, i.e. tabular output format 6).

## Output

A single gzip-compressed tabular similarity file (DIAMOND output format 6), named `<outputFile>.gz`, published to `outputDir`. Each row reports a query/target sequence pairing and its alignment statistics (percent identity, e-value, bit score, etc.).
