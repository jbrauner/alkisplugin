#!/usr/bin/perl

use strict;
use warnings;
use POSIX;

my $s;
my %v;

rename "metadata.txt", "metadata.tmp";
open I, "metadata.tmp";
open O, ">metadata.txt";
while( <I> ) {
	if( /^\s*\[(.*)\]$/ ) {
		$s = $1;
	} elsif( my($k,$v) = /^\s*(.*)\s*=\s*(.*)$/ ) {
		#$v{$s}{$1} = $2;
		$v{$k} = $v;

		next unless grep("-r", @ARGV);

		if( $k eq "version" ) {
			my($major,$minor,$patch) = split /\./, $v;
			$patch++;
			$v{version} = "$major.$minor.$patch";
			$_ = "version=$v{version}\n";
			print STDERR "New version:" . $v{version} . "\n";
		} elsif( $k eq "changelog" ) {
			$_ = "changelog=Änderungen in $v{version}\n \n";
			open F, "git log --date-order --date=short --pretty=%B \$(git log -1 --pretty=%h metadata.txt)..|";
			while(my $l = <F>) {
				next if $l =~ /^\s*$/;
				$_ .= " * $l";
			}
			close F;
			s/\s+$//;
			$_ .= "\n \n $v\n";
		}
	}
} continue {
	print O;
}
close O;
close I;
unlink "metadata.tmp";

my $date = strftime( "%FT%T.0", gmtime(time ) );

open F, ">plugin.xml";
print F <<EOF;
<?xml version = '1.0' encoding = 'UTF-8'?>
<?xml-stylesheet type="text/xsl" href="plugins.xsl" ?>
<plugins>
    <pyqgis_plugin name="$v{name}" version="$v{version}">
        <description><![CDATA[$v{description}]]></description>
        <version>$v{version}</version>
        <qgis_minimum_version>$v{qgisMinimumVersion}</qgis_minimum_version>
        <qgis_maximum_version>2.99.0</qgis_maximum_version>
        <homepage>http://www.norbit.de</homepage>
        <icon>./logo.svg</icon>
        <file_name>alkisplugin-$v{version}.zip</file_name>
        <author_name><![CDATA[$v{author}]]></author_name>
        <download_url>http://buten.norbit.de/~jef/qgis/alkisplugin-$v{version}.zip</download_url>
        <uploaded_by><![CDATA[$v{author}]]></uploaded_by>
        <create_date>2012-09-19T23:49:07.0</create_date>
        <update_date>$date</update_date>
        <experimental>False</experimental>
        <deprecated>False</deprecated>
        <tags><![CDATA[ALKIS,Liegenschaftskarte,Liegensschaftsbuch,GDAL,OGR,NAS,Normbasierte Austauschschnittstelle]]></tags>
    </pyqgis_plugin>
</plugins>
EOF
close F;
