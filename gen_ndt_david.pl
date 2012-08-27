#!/nokia/apps/tww/@sys/bin/perl -w

require 5.004;
use strict;
use Getopt::Long;
use File::Find;
use File::Basename;
use Cwd;
use IO::File;
use logging;
use Getopt::Std;

#print "\t gen_ndt.pl by Olina version 0.4\n";
#print "\t In this version, support image names with product_code, support product code with A-Z\n";
print "\n*********************************************************************************************\n";
print "*    gen_ndt_daviduan.pl update by David Duan(david.3.duan[AT]nokia.com) version 0.5        *\n";
print "*    In this version, support balabala....                                                  *";
print "\n*********************************************************************************************\n";

if (@ARGV<4) {
    die error( "
Usage: perl gen_ndt.pl <mcu> <color_diff> <user> <ReferenceVariant_path> 
       for example: perl gen_ndt.pl rm519 yes olzhang ./0500000_EURO_AA_LATIN_RED 
       
    -- mcu: the type designator (different for EU and US), lower case 
    -- color_diff: is there any content image difference for different color variants, yer/no
    -- user: this information will be recorded into 05xxxxx_info.xml file as the Originator Name
    -- ReferenceVariant_path: the path of reference variant code, based on which to generate NDTs
" );
}
my $mcu = shift;
my $color_diff = shift;
my $user = shift;
my $source = shift;

my $code;
my $type_designator;
my $region;
my $upperregion;
my $lowerregion;
my $ppm;
my $color;
my $keypad_country;

my $des_dir;
my $des_code;
my $des_description;
my $des_ppm;
my $des_image;
  
#starts of setting source value: based on 1 stardard variant, for example euro_aa code
#the path of source code is input by user
my $src_dir=$source;
my $td;
print "\tsource dir: $src_dir\n";
my $src_code= $1 if (basename $src_dir)=~ /(\w{7})_(.*)/;
print "\tsource code: $src_code\n";
#get file list of source code
my @file_list_code = glob "$src_dir/*.*";
my @file_list_contentconfig = glob "$src_dir/CONTENT_CONFIG/*.*";
my @file_list_EXT = glob "$src_dir/EXT_DCP_FILES/*";
my @file_list_varsetting = glob "$src_dir/VARIANT_SETTINGS/*.*";
#end of setting source value: based on 1 stardard variant, for example euro_aa code

#starting copy variant one by one based on input codelist.txt file    
#code format should be sth like: 0572503_RM-512_CTR_EURO_AA_BLACK_LATIN_DEMARK
#if one language pack goes to several country, i.e. ad_de & ad_tr, combine into one field like ad*de
#the code should be: 0572503_RM-512_CTR_EURO_AD*DE_BLACK_LATIN_GERMANY
open(CODE_F, "codelist.txt" );
my @code_n = <CODE_F>;
# count the numbers of codes

my $num = 0; 
foreach my $file_n ( @code_n ){

    chomp( $file_n );
    $ num = $num + 1;
    
    if( $file_n =~ /^(\w{7})_RM.*/ ){
        $code = $1;
    }
    if( $file_n =~ /(RM-[0-9]+)_.*/ ){
        $type_designator = $1;
        
    }
    #$file_n = quotemeta($file_n);
    if( $file_n =~ /NDT_(.*?)_(.*?)_(L_GREEN|D_PURPLE|D_GREY|.*?)_(.*?)_(.*)$/ ){
        $region = $1;
        $ppm = $2;
        $color = $3;
        $keypad_country = $4."_".$5;
        print "\n 1 keypad_country is : $keypad_country\n";
    }
    
    if( $ppm =~ m/(.*)\-(.*)/ ){
        $ppm = $1."_".$2;
    }
    
    $keypad_country = quotemeta($keypad_country);
    print "\n 2 after quotemeta: keypad_country is : $keypad_country\n";
    if( $keypad_country =~ m/(.*)_(.*)\\(.*)\\/ ){
        $keypad_country = $1."_".$2.$3;
        print "\n 2-if*keypad_country is : $keypad_country\n";
    }
    elsif( $keypad_country =~ m/(.*)_(.*)\\/ ){
        $keypad_country = $1."_".$2;
        print "\n 2-elsif*keypad_country is : $keypad_country\n";
    }

    print "\n=====================================================================\n";
    print "\t the $num code is: $file_n \n";    
    print "\t code is : $code\n";
    print "\t TD is : $type_designator\n";        
    print "\t region is : $region\n";
    print "\t language pack is : $ppm\n";
    print "\t color is : $color\n";
    print "\t 3*keypad_country is : $keypad_country";
    print "\n=====================================================================\n";

    $upperregion = uc ($region);
    $td = lc ($type_designator);

    if( $td =~ m/(.*)\-(.*)/ ){
        $td = $1.$2; 
    }

    #starts of setting target dir according to different region
    #construct the code dir name
    $des_dir = $code."_".$region."_".$ppm."_".$color."_".$keypad_country;
        
    if ( $region =~ /^BRA/ ){
        print "-------matched BRAZIL----------\n";
        #$des_dir = $brazil."/".$des_dir;
        $region = "brazil";
        #this lowerregion is used for common_cc files
        $lowerregion = "brazil";
    }

    if ( $region =~ /^CH/ ){
        print "-------matched CHINA----------\n";
        #$des_dir = $china."/".$des_dir;
        $region = "china";
        $lowerregion = "china";
    }

    if (( $region =~ /^EURA/ ) || ( $region =~ /^EUROA/ )) {
        print "-------matched EURASIA or EUROASIA----------\n";
        #$des_dir = $eurasia."/".$des_dir;
        $region = "euroasia";
        $lowerregion = "euro";
    }
    elsif ( $region =~ /^EUR/ ){
        print "-------matched EURO----------\n";
        #$des_dir = $euro."/".$des_dir;
        $region = "euro";
        $lowerregion = "euro";
    }

    if ( $region =~ /^IND/ ){
        print "-------matched INDIA----------\n";
        #$des_dir = $india."/".$des_dir;
        $region = "india";
        $lowerregion = "india";
    }

    if ( $region =~ /^LTA/ ){
        print "-------matched LTA----------\n";
        #$des_dir = $lta."/".$des_dir;
        $region = "lta";
        $lowerregion = "lta";
    }

    if ( $region =~ /^MEA/ ){
        print "-------matched MEA----------\n";
        #$des_dir = $mea."/".$des_dir;
        $region = "mea";
        $lowerregion = "mea";
    }

    if ( $region =~ /^MENA/ ){
        print "-------matched MENA----------\n";
        #$des_dir = $mea."/".$des_dir;
        $region = "mena";
        $lowerregion = "mea";
    }

    if ( $region =~ /^SEAP/ ){
        print "-------matched SEAP----------\n";
        #$des_dir = $seap."/".$des_dir;
        $region = "apac";
        $lowerregion = "apac";
    }

    if ( $region =~ /^APAC/ ){
        print "-------matched APAC----------\n";
        #$des_dir = $seap."/".$des_dir;
        $region = "apac";
        $lowerregion = "apac";
    }

    if ( $region =~ /^SSA/ ){
        print "-------matched SSA----------\n";
        #$des_dir = $ssa."/".$des_dir;
        $region = "ssa";
        $lowerregion = "mea";
    }

    if ( $region =~ /^NA/ ){
        print "-------matched NA----------\n";
        #$des_dir = $na."/".$des_dir;
        $region = "na";
        $lowerregion = "na";
    }

    my $regiondir = $td."_".$region."_nokia_defaults";
    mkdir $regiondir;
    #combine the full code path
    $des_dir = $regiondir."/".$des_dir;
    print "\n==============destination dir is : $des_dir==============\n";
    #ends of setting target dir according to different region


    #starts of setting target code attribute, like code, description, ppm, image
    $des_code= $code;
    print "\n==============destination code: $des_code==============\n";
    $des_description= substr((basename $des_dir),8);

    $ppm = lc ($ppm);
    $des_ppm = lc($ppm);
    #remove the use case for AD_DE & AD_TU, consider new language pack used in Buffalo, like M_L, M_A
    #if( $ppm =~ m/(.*)_(.*)/ ){
    #    $des_ppm = $1;
    #}

    #target image: different based on color difference input
    $color = lc($color);
    #since it supports image name with product code, remove the color information
    $des_image = $ppm;

    print "target image name is : $des_image  \n";
    #ends of setting target code attribute, like code, description, ppm, image

    #starts of mkdir and standard sub-directory for each variant code
    mkdir $des_dir;
    mkdir "$des_dir/CONTENT_CONFIG";
    mkdir "$des_dir/EXT_DCP_FILES";
    mkdir "$des_dir/VariantConfiguration";

    #ends of mkdir and standard sub-directory for each variant code

    #Starting copy files and necessary replacement also, step 1 to 5
    #step 1 copy files under code level, change 05xxxxx_info.xml file
    print "\n[step 1] copy files under code level, change 05xxxxx_info.xml file\n";

    foreach my $file_code (@file_list_code){
        print "copying files under code level: $file_code \n";
        my $short_name = basename $file_code;
            
        if ($file_code =~ /_info\.xml$/){
            `cp $src_dir/$src_code\_info.xml $des_dir/$des_code\_info.xml`;
            `perl -wpi -e 's/$src_code/$des_code/g' $des_dir/$des_code\_info.xml`;
            # Replace the description in Info file
            `perl -wpi -e 's/<Description>.*</<Description>$type_designator $des_description\</g' $des_dir/$des_code\_info.xml`;
            # Replace the originator name by user input
            `perl -wpi -e 's/<Name>.*</<Name>$user\</g' $des_dir/$des_code\_info.xml`;
        }else {
            # For RAP products, copying other files like 05xxxxx_hwc_ccc.xml, nothing to replace
            $short_name =~ s/$src_code/$des_code/;
            `cp $file_code $des_dir/$short_name`;
        }
    }

    #step 2 create content in Content_Config dir
    print "\n[step 2] create content in CONTENT_CONFIG dir\n";

    foreach my $file_content (@file_list_contentconfig){
        print "copying CONTENT_CONFIG files: $file_content \n";

        if ($file_content =~ /_ism\.xml$/){
        `cp $file_content $des_dir/CONTENT_CONFIG/$des_code\_ism.xml`;
        change_ism( "$des_dir/CONTENT_CONFIG/$des_code\_ism.xml" );
        }elsif ($file_content =~ /package_.*\.dconf$/){
        `cp $file_content $des_dir/CONTENT_CONFIG/package\_$des_image\_$des_code\.dconf`;
        change_dconf( "$des_dir/CONTENT_CONFIG/package\_$des_image\_$des_code\.dconf");
        }elsif ($file_content =~ /package_.*\.ducp$/){
        `cp $file_content $des_dir/CONTENT_CONFIG/package\_$des_image.ducp`;
        }elsif ($file_content =~ /package_.*\.conf$/){
        `cp $file_content $des_dir/CONTENT_CONFIG/package\_$des_image.conf`;
        }elsif ($file_content =~ /package_.*\.zip$/){
        `cp $file_content $des_dir/CONTENT_CONFIG/package\_$des_image.zip`;
        }else {
            `cp $file_content $des_dir/CONTENT_CONFIG/`;
        }
    }

    #step 3 create content in EXT_DCP_FILES
    print "\n[step 3] create content in EXT_DCP_FILES\n";
    foreach my $file_ext (@file_list_EXT){
        print "copying EXT_DCP_FILES: $file_ext \n";
        my $short_name = basename $file_ext;
        
        if( $file_ext =~ /.spr/i ){
            my $spr_name = $type_designator;
            if( $spr_name =~ /-/ ){
                $spr_name =~ s/-//;
            }
            `cp $file_ext $des_dir/EXT_DCP_FILES/$spr_name\_$des_code\.spr`;
        }
        else{
                $short_name =~ s/$src_code/$des_code/;
                `cp $file_ext $des_dir/EXT_DCP_FILES/$short_name`;
        
        }
    }

    #step 4 create content in VARIANT_SETTINGS
    print "\n[step 4] create content in VARIANT_SETTINGS\n";
    foreach my $file_varsetting (@file_list_varsetting){
        print "copying VARIANT_SETTING files: $file_varsetting \n";
        my $short_name = basename $file_varsetting;
        $short_name =~ s/$src_code/$des_code/;
        `cp $file_varsetting $des_dir/VARIANT_SETTINGS/$short_name`;
    }

    #step 5 create content in VariantConfiguration
    print "\n[step 5] create content in VariantConfiguration\n";
    print "copying variantconfig files to des dir: $des_dir \n";
    `cp $src_dir/VariantConfiguration/$src_code.xml $des_dir/VariantConfiguration/$des_code.xml`;
    `perl -wpi -e 's/$src_code/$des_code/g' $des_dir/VariantConfiguration/$des_code.xml`;
    `perl -wpi -e 's/\>.*\.mcusw\</\>$mcu\__&swversion;\.mcusw\</g' $des_dir/VariantConfiguration/$des_code.xml`;
    `perl -wpi -e 's/\>.*\.ppm_.*\</\>$mcu\__&swversion;\.ppm_$des_ppm\</g' $des_dir/VariantConfiguration/$des_code.xml`;
    `perl -wpi -e 's/\>.*\.image_.*\</\>$mcu\__&swversion;\.image_$des_image\_$des_code</g' $des_dir/VariantConfiguration/$des_code.xml`;
    `perl -wpi -e 's/<TypeDesignator>.*</<TypeDesignator>$type_designator\</g' $des_dir/VariantConfiguration/$des_code.xml`;
    `perl -wpi -e 's/<Description>.*</<Description>$type_designator $des_description\</g' $des_dir/VariantConfiguration/$des_code.xml`;


} # end of foreach my $file_n ( @code_n )
#end of copy variant one by one based on input codelist.txt file

#In the end, print how many codes being copied
print "\t ends of totally copied codes: $num \n"; 

###################################################################################
sub change_ism
{
    my $fname=shift;

    `perl -wpi -e 's[parent="../../../.*\_common_settings][parent="../../../$td\_common_settings]g' $fname`;

#replace ISM parent according to region (from code)
  print " trying to replacing ISM parent: upper case of region is: $upperregion===\n"; 
  if ($des_ppm eq "r"){
    $upperregion = "CHINA_CN"
  }
  if ($des_ppm eq "p"){
    $upperregion = "CHINA_TW"
  }
  if ($des_ppm eq "q"){
    $upperregion = "CHINA_HK"
  }
    `perl -wpi -e 's{\]/.*\.xml}{\]/$upperregion\.xml}' $fname`;
}

sub change_dconf
{
    my $fname=shift;
    #Change the new ucp file name according to target iamge name    
    `perl -wpi -e 's/new File=\"package_.*\.ucp\"/new File=\"package_$des_image\_$des_code\.ucp\"/g' $fname`;
    
    my $dcolor = $color;    
    my $lowerregion_menu=$lowerregion;

    if ($des_ppm eq "r"){
        $lowerregion_menu = "cn"
    }
    if ($des_ppm eq "p"){
        $lowerregion_menu = "tw"
    }
    if ($des_ppm eq "q"){
        $lowerregion_menu = "hk"
    }
    if ($color =~ /gray/ || $color =~ /grey/){
        $dcolor = "dgray"
    }
    if ($color =~ /black/){
        $dcolor = "jblack"
    }
    if ($color =~ /white/){
        $dcolor = "swhite"
    }
    if ($color =~ /blue/){
        $dcolor = "dblue"
    }
    if ($color =~ /l_green/){
        $dcolor = "lgreen"
    }
    if ($color =~ /d_purple/){
        $dcolor = "purple"
    }

    # Update the mapping to Package_pre_*.ucp", add pre_color if with color difference
    if ($color_diff =~ m/y/) {
        `sed -i '6d' $fname`;
        `perl -wpi -e 's/add File="package__pre_.*\.ucp"/add File="package__pre_$des_ppm\.ucp"\\nadd File="package__pre_$dcolor\.ucp"/g' $fname`;
    }
    else {
        `perl -wpi -e 's/add File="package__pre_.*\.ucp"/add File="package__pre_$des_ppm\.ucp"/g' $fname`;
    }      

    #Change the color name to be same with target color name
    `perl -wpi -e 's/delete Name="User Content Package _pre_jblack"/delete Name="User Content Package _pre_$dcolor"/g' $fname`;

    #Change the ducp name to be same with target image name
    `perl -wpi -e 's/add File="package_.*\.ducp"/add File="package_$des_image\.ducp"/g' $fname`;
    
    #Change the color name to be same with target color name
    `perl -wpi -e 's[RD\/product-data_.*\.confml" Name="product-data.confml"][RD\/product-data_$lowerregion\.confml" Name="product-data.confml"]g' $fname`;
    
    #Change the color name to be same with target color name
    `perl -wpi -e 's[menu_settings\/menusettings_.*\.xml" Name="menusettings.xml"][menu_settings\/menusettings_$lowerregion_menu\.xml" Name="menusettings.xml"]g' $fname`;
   
    # replace product commong setting path    
    `perl -wpi -e 's[add File="../../../.*\_common_settings][add File="../../../$td\_common_settings]g' $fname`;
    # replace cc file based on region (from code), Do not change this for we put all.
    #   `perl -wpi -e 's[add File="../../../common_cc_collection/cc/cc_reg_.*\.ducp"][add File="../../../common_cc_collection/cc/cc_reg_$lowerregion\.ducp"]g' $fname`;

    #Change the Name information of image
    `perl -wpi -e 's/^edit Name=.*/edit Name=\"User Content Package _pre_$des_ppm\"  Newname=\"User Content Package $des_image\_$des_code\" Replace=\"Content: $des_image\_$des_code\"/g' $fname`;

}
