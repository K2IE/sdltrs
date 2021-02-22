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

#import "DebuggerManager.h"
#import "DebuggerWindow.h"


@implementation DebuggerWindow
/*------------------------------------------------------------------------------
*  init -
*-----------------------------------------------------------------------------*/
-(id) init
{
	id me;
	
	me = [super init];
	
	return(me);
}

- (void)sendEvent:(NSEvent *)anEvent
{
	unichar firstChar;
	
    if ([anEvent type] == NSKeyDown) {
		firstChar = [[anEvent characters] characterAtIndex:0];
		if (firstChar == NSUpArrowFunctionKey) {
			[[DebuggerManager sharedInstance] debuggerUpArrow];
			return;
			}
		else if (firstChar == NSDownArrowFunctionKey) {
			[[DebuggerManager sharedInstance] debuggerDownArrow];
			return;
			}
    }
    [super sendEvent:anEvent];
}

/*------------------------------------------------------------------------------
*  selectAll - All window classes need this in this program, even if they have
*   nothing to select, since this method is send to the key window whenever
*   the Select All menu item is chosen.
*-----------------------------------------------------------------------------*/
- (void)selectAll:(id)sender
{
}

@end
