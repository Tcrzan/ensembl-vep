=head1 LICENSE

Copyright [1999-2016] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut


=head1 CONTACT

 Please email comments or questions to the public Ensembl
 developers list at <http://lists.ensembl.org/mailman/listinfo/dev>.

 Questions may also be sent to the Ensembl help desk at
 <http://www.ensembl.org/Help/Contact>.

=cut

# EnsEMBL module for Bio::EnsEMBL::VEP::AnnotationSource::File::GFF
#
#

=head1 NAME

Bio::EnsEMBL::VEP::AnnotationSource::File::GFF - GFF annotation source

=cut


use strict;
use warnings;

package Bio::EnsEMBL::VEP::AnnotationSource::File::GFF;

use Bio::EnsEMBL::Utils::Exception qw(throw warning);
use Bio::EnsEMBL::IO::Parser::GFF3Tabix;

use base qw(Bio::EnsEMBL::VEP::AnnotationSource::File::BaseGXF);

my %INCLUDE_FEATURE_TYPES = map {$_ => 1} qw(
  aberrant_processed_transcript
  CDS
  C_gene_segment
  exon
  gene
  J_gene_segment
  lincRNA
  lincRNA_gene
  miRNA
  miRNA_gene
  mt_gene
  NMD_transcript_variant
  processed_pseudogene
  processed_transcript
  pseudogene
  pseudogenic_transcript
  RNA
  rRNA
  rRNA_gene
  snoRNA
  snoRNA_gene
  snRNA
  snRNA_gene
  supercontig
  transcript
  VD_gene_segment
  V_gene_segment

  CDS
  C_gene_segment
  D_gene_segment
  exon
  gene
  J_gene_segment
  mRNA
  ncRNA
  primary_transcript
  rRNA
  transcript
  tRNA
  V_gene_segment
);

sub parser {
  my $self = shift;
  return $self->{parser} ||= Bio::EnsEMBL::IO::Parser::GFF3Tabix->open($self->file, must_parse_metadata => 0);
}

sub include_feature_types {
  return \%INCLUDE_FEATURE_TYPES;
}

sub _record_get_parent_id {
  my ($self, $record) = @_;

  if(!exists($record->{_parent_id})) {
    my $attributes = $record->{attributes};
    $record->{_parent_id} = $attributes->{Parent} || $attributes->{parent};
  }

  return $record->{_parent_id};
}

sub _record_get_id {
  my ($self, $record) = @_;

  if(!exists($record->{_id})) {
    my $attributes = $record->{attributes};
    $record->{_id} = $attributes->{ID} || $attributes->{Name} || $attributes->{id} || $attributes->{name};
  }

  return $record->{_id};
}

sub _record_get_biotype {
  my ($self, $record, $gene_record) = @_;

  if(!exists($record->{_biotype})) {

    # Ensembl-y GFFs have biotype as an attribute
    my $biotype = $record->{attributes}->{biotype};

    # others we need to (guess) work it out
    if(!$biotype) {
      my $type = lc($record->{type});

      if($type eq 'mrna') {
        $biotype = 'protein_coding';
      }
      elsif($type eq 'ncrna') {
        $biotype = $record->{attributes}->{ncrna_class};
      }
      elsif($type =~ /^([a-z]+)_gene_segment$/) {
        $biotype = 'IG_'.uc($1).'_gene';
      }
      elsif($gene_record && ($gene_record->{attributes}->{description} || '') =~ /^microRNA/) {
        $biotype = 'miRNA';
      }
      elsif($record->{attributes}->{gbkey}) {
        $biotype = $record->{attributes}->{gbkey};
      }
    }

    $record->{_biotype} = $biotype;
  }

  return $record->{_biotype};
}

1;