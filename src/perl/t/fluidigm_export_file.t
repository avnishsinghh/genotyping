
# Tests WTSI::NPG::Genotyping::FluidigmExportFile

use utf8;

use strict;
use warnings;

use File::Compare;
use File::Temp qw(tempdir);

use Test::More tests => 299;
use Test::Exception;

Log::Log4perl::init('etc/log4perl_tests.conf');

BEGIN { use_ok('WTSI::NPG::Genotyping::FluidigmExportFile'); }
require_ok('WTSI::NPG::Genotyping::FluidigmExportFile');

my $data_path = './t/fluidigm_export_file';
my $complete_file = "$data_path/complete.csv";
my $header = "$data_path/header.txt";
my $body = "$data_path/body.txt";

ok(WTSI::NPG::Genotyping::FluidigmExportFile->new
   ({file_name => $complete_file}));
dies_ok { WTSI::NPG::Genotyping::FluidigmExportFile->new
  ({file_name => 'no_such_file_exists'}) }
  "Expected to fail constructing with missing file";
dies_ok { WTSI::NPG::Genotyping::FluidigmExportFile->new() }
  "Expected to fail constructing with no arguments";
dies_ok { WTSI::NPG::Genotyping::FluidigmExportFile->new($header) }
  "Expected to fail parsing when body is missing";
dies_ok { WTSI::NPG::Genotyping::FluidigmExportFile->new($body) }
  "Expected to fail parsing when header is missing";

my $export = WTSI::NPG::Genotyping::FluidigmExportFile->new
  ({file_name => $complete_file});
is($export->fluidigm_barcode, '1381735059', 'Fluidigm barcode is 1381735059');
cmp_ok($export->confidence_threshold, '==', 65, 'Confidence threshold == 65');
cmp_ok($export->size, '==', 96, 'Number of samples differs == 96');

# Each sample should have 96 assay results
my @sample_addresses;
for (my $i = 1; $i <= 96; $i++) {
  push(@sample_addresses, sprintf("S%02d", $i));
}
is_deeply($export->addresses, \@sample_addresses,
          'Expected sample addresses') or diag explain $export->addresses;

foreach my $address (@sample_addresses) {
  cmp_ok(@{$export->sample_assays($address)}, '==', 96,
         "Sample assay count at address $address");
}

my $tmpdir = tempdir(CLEANUP => 1);
foreach my $address (@sample_addresses) {
  my $expected_file = sprintf("%s/%s_%s.csv", $data_path, $address,
                              $export->fluidigm_barcode);
  my $test_file = sprintf("%s/%s_%s.csv", $tmpdir, $address,
                          $export->fluidigm_barcode);

  cmp_ok($export->write_sample_assays($address, $test_file), '==', 96,
         "Number of records written to $test_file");

  ok(compare($test_file, $expected_file) == 0,
     "$test_file is identical to $expected_file");

  unlink $test_file;
}
