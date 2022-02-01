/******************************************************************************
 * snesmod converter
 * (C) 2009-2016 Mukunda Johnson
 * Modifications by Augustus Blackheart 2010, 2014-2016
 ******************************************************************************/
 
#include <string>
#include <stdio.h>
#include "help.h"
#include "inputdata.h"
#include "itloader.h"
#include "it2spc.h"

#ifndef SM_VERSION
#define SM_VERSION	"0.1.6"
#endif

#define APP_VERSION	SM_VERSION

const char PROGRAM_INFO[] = {
	"SMCONV v" APP_VERSION " (C) 2009-2017 Mukunda Johnson (www.mukunda.com)\n"
	"Modifications to conversion tool by Augustus Blackheart.\n"
};

std::string PATH;
bool INFO;
bool VERBOSE;
int LINE_STYLE;

int main( int argc, char *argv[] ) {
	
	ConversionInput::OperationData od( argc, argv );

	INFO = od.info_mode;
	VERBOSE = od.verbose_mode;
	LINE_STYLE = od.line_style;

	printf( PROGRAM_INFO );

	if( argc < 2 ) { od.show_help = true; }

	if( od.show_help ) {
		printf( USAGE );
		printf( OPTIONS );
		return 0;
	}

	if( od.show_doc ) {
		printf( USAGE );
		printf( DOC );
		return 0;
	}

	IT2SPC::Driver driver( od.driver );
	if( od.driver == "h" || od.driver == "help" || od.driver == "?" || od.driver == "info" ) {
		printf( USAGE );
		printf( DRIVER_INFO );
		return 0;
	}

	if( od.output.empty() ) {
		printf( "error: missing output file\n" );
		return 0;
	}

	if( od.files.empty() ) {
		printf( "error: missing input file\n" );
		return 0;
	}

	if( VERBOSE ) { printf( "Loading modules...\n" ); }

	ITLoader::Bank bank( od.files );

	if( VERBOSE ) { printf( "Starting conversion...\n" ); }

	IT2SPC::Info();
	IT2SPC::Bank result( bank, od.hirom );
	
	// export products
	if( od.spc_mode ) {
		result.MakeSPC( od.output.c_str() );
	} else {
		result.Export( od.output.c_str() );

	}
	
	return 0;
}
