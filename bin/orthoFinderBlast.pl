#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

my ($query,$database,$filePath,$queryNumber,$dataNumber);

&GetOptions("query=s"=> \$query,
            "database=s"=> \$database);

if ($query =~ /^(.+)Species(\d+).fa/) {
    $filePath = $1;
    $queryNumber = $2;
}
else {
    die;
}
if ($database =~ /^(.+)Species(\d+).fa/) {
    $dataNumber = $2;
}
else {
    die;
}

system("diamond blastp --ignore-warnings -d ${filePath}diamondDBSpecies${dataNumber}.dmnd -q ${filePath}Species${queryNumber}.fa -o Blast${queryNumber}_${dataNumber}.txt.gz -f 6 qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore qlen slen nident positive qframe qstrand gaps qseq --more-sensitive -p 1 --quiet -e 0.001 --compress 1");
