#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

my ($query,$database,$filePath,$queryNumber,$dataNumber,$previousBlasts,$sequences_id_file,$species_id_file);

&GetOptions("query=s"=> \$query,
            "database=s"=> \$database,
	    "sequences_id_file=s"=> \$sequences_id_file,
	    "species_id_file=s"=> \$species_id_file
           );

# Read species ID file
open my $fh_species, '<', $species_id_file or die "Cannot open $species_id_file: $!";
my %id_to_species_map;
while (my $line = <$fh_species>) {
    chomp $line;
    if ($line =~ /^(\d+):\s+(\S+)\.fasta\.fasta/) {
        my ($id, $species) = ($1, $2);
        $id_to_species_map{$id} = $species;
    }
}
close $fh_species;

open $fh_species, '<', $species_id_file or die "Cannot open $species_id_file: $!";
my %species_to_ids_map;
while (my $line = <$fh_species>) {
    chomp $line;
    if ($line =~ /^(\d+):\s+(\S+)\.fasta\.fasta/) {
        my ($id, $species) = ($1, $2);
        $id_to_species_map{$species} = $id;
    }
}
close $fh_species;

# Read sequences ID file
open my $fh_sequences, '<', $sequences_id_file or die "Cannot open $sequences_id_file: $!";
my %real_to_new_seqs_map;
while (my $line = <$fh_sequences>) {
    chomp $line;
    if ($line =~ /^(\d+_\d+):\s+(.+)/) {
        my ($new, $real) = ($1, $2);
        $real_to_new_seqs_map{$real} = $new;
    }
}
close $fh_sequences;

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

my $queryOrganism = $id_to_species_map{$queryNumber};
my $dataOrganism = $id_to_species_map{$dataNumber};

if (-e "/previousBlasts/${queryOrganism}_${dataOrganism}.txt.gz") {
    system("cp /previousBlasts/${queryOrganism}_${dataOrganism}.txt.gz ./Blast${queryNumber}_${dataNumber}.txt.gz");
    system("gunzip Blast${queryNumber}_${dataNumber}.txt.gz");
    # Rename files in the output directory
    open my $inputFile, '<', "Blast${queryNumber}_${dataNumber}.txt" or die "Cannot open \"Blast${queryNumber}_${dataNumber}.txt\": $!";
    my $new_name_temp = "Blast${queryNumber}_${dataNumber}.txt" . ".temp";
    open(OUT,">$new_name_temp");
    while (my $line = <$inputFile>) {
   	chomp $line;
	if ($line =~ /^([^\t]*)\t([^\t]*)\t(.+)$/) {
            my ($organism_first_sequence, $organism_second_sequence, $data) = ($1,$2,$3);
	    my $new_first_sequence = $real_to_new_seqs_map{$organism_first_sequence};
	    my $new_second_sequence = $real_to_new_seqs_map{$organism_second_sequence};
	    print OUT "$new_first_sequence\t$new_second_sequence\t$data\n";
        }
	else {
            die "$line Invalid blast format\n";
	}
    }
    system("mv $new_name_temp Blast${queryNumber}_${dataNumber}.txt");
    system("gzip Blast${queryNumber}_${dataNumber}.txt");
    close OUT;
}
else {
    print "Calculating New!\n";
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
}
