use TAPER::submissionAgreement ;
my $sa = TAPER::submissionAgreement ->from_xml_file('./example.xml');
print $sa->to_xml_string;
