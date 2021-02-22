/* Copyright (c): 2006, Mark Grebe */

/* Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
*/

/*
   Modified by Mark Grebe, 2006
   Last modified on Wed May 07 09:12:00 MST 2006 by markgrebe
*/

#import "PrintOutputController.h"
#import "Preferences.h"
#import "PrintableString.h"
#import "PrinterView.h"
#import "EpsonFX80Simulator.h"
#import "Atari1020Simulator.h"
#import "MediaManager.h"
#import "trs.h"

#define PAGE_WIDTH 8.3*72.0

extern NSWindow *appWindow;

// 'C' routine that emulator core can call
void PrintOutputControllerPrintChar(char character) {
    [[PrintOutputController sharedInstance] printChar:character];
}
void PrintOutputControllerSelectPrinter(int printer) {
    [[PrintOutputController sharedInstance] selectPrinter:printer];
}

@implementation PrintOutputController

static PrintOutputController *sharedInstance = nil;
static PrinterView *ourPrinterView;
static NSMutableArray *printArray;

+ (PrintOutputController *)sharedInstance {
    return sharedInstance ? sharedInstance : [[self alloc] init];
}

- (id)init {
    if (sharedInstance) {
		[self dealloc];
    } else {
        sharedInstance = self;	
		[super initWithWindowNibName:@"PrintOutput" owner:self];
        /* load the reset confirm nib  */
        if (!mResetConfirmButton) {
			if (![NSBundle loadNibNamed:@"PrintOutputConfirm" owner:self])  {
				NSLog(@"Failed to load PrintOutputConfirm.nib");
				NSBeep();
				return nil;
				}
			}
		[[mResetConfirmButton window] setExcludedFromWindowsMenu:YES];
		[[mResetConfirmButton window] setMenu:nil];
		printArray = [NSMutableArray arrayWithCapacity:100];
		preview = YES;
		numPages = 1;
		printOffset = 0.0;
		[printArray retain];
	}
	
    return sharedInstance;
}

- (int)calcNumPages
{
	PrintableString *element;
	int numPrintElements,i;
	float maxYPos = 0.0;
	float yPos;
	int newNumPages;
	float formLength = [currentPrinter getFormLength];
	float vertPos = [currentPrinter getVertPosition];
	
	// Find the print element at the largest Y coordinate.
	numPrintElements = [printArray count];
	for (i=0;i<numPrintElements;i++)
		{
		element = [printArray objectAtIndex:i];
		yPos = [element getYLocation]; 
		if (yPos > maxYPos)
			maxYPos = yPos;
		}
	
	if (vertPos > maxYPos)
		maxYPos = vertPos;
		
	newNumPages = (int) (maxYPos/formLength);
	newNumPages++;
	
	return newNumPages;
}

-(void)calcPrinterOffset
{
	PrintableString *element;
	int numPrintElements,i;
	float yPos;
	printOffset = 0.0;
	
	if ([currentPrinter isAutoPageAdjustEnabled])
		{
	
		// Find the print element at the smallest Y coordinate.
		numPrintElements = [printArray count];
		for (i=0;i<numPrintElements;i++)
			{
			element = [printArray objectAtIndex:i];
			yPos = [element getMinYLocation]; 
			if (yPos < printOffset)
				printOffset = yPos;
			}
		}
		
	if (printOffset < 0.0)
		printOffset = -printOffset + 12.0;
}

- (void)updatePages
{
	float formLength = [currentPrinter getFormLength];
	float vertPos = [currentPrinter getVertPosition];
	
	numPages = [self calcNumPages];
	[ourPrinterView updateVerticlePosition:[currentPrinter getVertPosition]];
	[ourPrinterView scrollRectToVisible:NSMakeRect(0,vertPos,1.0,12.0)];
	[ourPrinterView setFrame:NSMakeRect(0,0,PAGE_WIDTH,numPages*formLength)];
	
	[ourPrinterView setNeedsDisplay:YES];
}

-(void)printChar:(char) character
{
	if (currentPrinter != nil)
		[currentPrinter printChar:character];
}

- (void)showPrinterOutput:(id)sender
{	
	NSRect printRect;
	float formLength = [currentPrinter getFormLength];
	
	preview = YES;
	
	numPages = [self calcNumPages];
	[self calcPrinterOffset];
	
	// Allocate our view of the proper size
	printRect = NSMakeRect(0,0,8.3*72.0,numPages*formLength);
	ourPrinterView = [PrinterView alloc];
	// Init it and make sure it knows we are it's owner
	[ourPrinterView initWithFrame:printRect:self:formLength:[currentPrinter getVertPosition]];
	
    [NSApp beginSheet:[self window]
            modalForWindow: appWindow
            modalDelegate: nil
            didEndSelector: nil
            contextInfo: nil];
			
	[mMainScrollView setHasVerticalScroller:YES];
	[mMainScrollView setDocumentView:ourPrinterView];
	[mMainScrollView setDrawsBackground:YES];
	
	if ([currentPrinter getPenColor] != nil)
		[mPenChangeButton setEnabled:YES];
	else
		[mPenChangeButton setEnabled:NO];
		
	[self setPenButtonColor];
	
	[self updatePages];
	
    [NSApp runModalForWindow: [self window]];
    // Sheet is up here.
    [NSApp endSheet: [self window]];
    [[self window] orderOut: self];
	[ourPrinterView release];
}

-(void)setPenButtonColor
{
	NSAttributedString *penString;
	
	if ([mPenChangeButton isEnabled])
		{
		penString = [NSAttributedString alloc];
		[penString initWithString:@"Pen Change" 
					attributes:[NSDictionary dictionaryWithObjectsAndKeys:
								[currentPrinter getPenColor], NSForegroundColorAttributeName,
								[NSFont systemFontOfSize:0.0], NSFontAttributeName,
								nil]];
		[mPenChangeButton setAttributedTitle:penString];
		[penString autorelease];
		}	
}

- (IBAction)onContinue:(id)sender
{
    [NSApp stopModal];
}

- (IBAction)onDelete:(id)sender
{
	[printArray removeAllObjects];
	[currentPrinter topBlankForm];
    [NSApp stopModal];
}

- (IBAction)onResetPrinter:(id)sender
{
    if (trs_printer == TEXT_PRINTER) {
        trs_printer_reset();
        return;
        }
	if (sender != self)
		{
		// Check if page is emtpy
		if ([printArray count] != 0)
			{
			if (![self resetConfirm])
				return;
			}
		}
	[printArray removeAllObjects];
	[currentPrinter reset];
	[self setPenButtonColor];
	[self updatePages];
}

- (int)resetConfirm 
{
    return([NSApp runModalForWindow:[mResetConfirmButton window]]);             
}

- (IBAction)resetConfirmYes:(id)sender 
{
    [NSApp stopModalWithCode:1];
    [[sender window] close];
}

- (IBAction)resetConfirmNo:(id)sender
{
    [NSApp stopModalWithCode:0];
    [[sender window] close];
}

- (IBAction)onSelectPrinter:(id)sender
{
	[self selectPrinter:[sender tag]];
}

- (void)selectPrinter:(int)printer
{
	trs_printer = printer;
	
	switch(printer)
		{
		case 0:
		case 1:
			[self setPrinter:nil];
			break;
		case 2:
			[self setPrinter:[EpsonFX80Simulator sharedInstance]];
			[self onResetPrinter:self];
			break;
		case 3:
			[self setPrinter:[Atari1020Simulator sharedInstance]];
			[self onResetPrinter:self];
			break;
		}
		
	[[MediaManager sharedInstance] updateInfo];
}

- (IBAction)onSaveAs:(id)sender
{
    NSPrintInfo *printInfo;
    NSPrintInfo *sharedInfo;
    NSPrintOperation *printOp;
    NSMutableDictionary *printInfoDict;
    NSMutableDictionary *sharedDict;
    NSSavePanel *savePanel = nil;
	NSString *directory;
    
    savePanel = [NSSavePanel savePanel];
    [savePanel setRequiredFileType:@"pdf"];
	directory = [NSString stringWithCString:trs_printer_dir];
    
    if ([savePanel runModalForDirectory:directory file:nil] == NSOKButton)
		{
		preview = NO;
		
		sharedInfo = [NSPrintInfo sharedPrintInfo];
		sharedDict = [sharedInfo dictionary];
		printInfoDict = [NSMutableDictionary dictionaryWithDictionary:sharedDict];
		[printInfoDict setObject:NSPrintSaveJob forKey:NSPrintJobDisposition];
		[printInfoDict setObject:[savePanel filename] forKey:NSPrintSavePath];
	
		printInfo = [[NSPrintInfo alloc] initWithDictionary: printInfoDict];
		[printInfo setLeftMargin:0.0];
		[printInfo setRightMargin:0.0];
		[printInfo setTopMargin:0.0];
		[printInfo setBottomMargin:0.0];
		[printInfo setHorizontalPagination: NSAutoPagination];
		[printInfo setVerticalPagination: NSAutoPagination];
		[printInfo setVerticallyCentered:NO];
		[printInfo setPaperSize:NSMakeSize(PAGE_WIDTH, [currentPrinter getFormLength])];
	
		printOp = [NSPrintOperation printOperationWithView:ourPrinterView 
									printInfo:printInfo];
		[printOp setShowPanels:NO];
		[printOp runOperation];
		
		[printArray removeAllObjects];
		[currentPrinter topBlankForm];
		
		[NSApp stopModal];
		}
		
}


- (IBAction)onSkipLine:(id)sender
{
	[currentPrinter executeLineFeed];
	[self updatePages];
}

- (IBAction)onRevSkipLine:(id)sender
{
	[currentPrinter executeRevLineFeed];
	[self updatePages];
}

- (IBAction)onSkipPage:(id)sender
{
	[currentPrinter executeFormFeed];
	[self updatePages];
}

- (void)addToPrintArray:(NSObject *)object
{
	[printArray addObject:object];
}

- (NSArray *)getPrintArray
{
	return printArray;
}

- (bool)isPreview
{
	return preview;
}

-(float)getPrintOffset
{
	return printOffset;
}

- (void)setPrinter:(NSObject *)printer
{
	currentPrinter = (PrinterSimulator *)printer;
}

- (IBAction)onChangePen:(id)sender
{
	[currentPrinter executePenChange];
	[self setPenButtonColor];
}

- (void)enablePenChange:(BOOL)enable
{
	[mPenChangeButton setEnabled:enable];
}

@end
