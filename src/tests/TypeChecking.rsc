module tests::TypeChecking

import lang::StateDuino::ast::Main;
import lang::StateDuino::ast::Load;
import lang::StateDuino::semantics::Checker;
import Message;
import Set;
import IO;

private set[Message] runFastCheckOn(str input) {
	return fastCheck(getStateMachine(input));
}
private set[Message] runBigCheckOn(str input) {
	return fullCheck(getStateMachine(input));
}
private bool checkContainsErrorMessage(str input, str message) {
	set[Message] messages = runFastCheckOn(input);
	if (error(message, _) <- messages) {
		return true;
	}
	return false;
}
private bool verifyContainsErrorMessage(str input, str message) {
	set[Message] messages = runBigCheckOn(input);
	if (error(message, _) <- messages) {
		return true;
	}
	return false;
}
private bool verifyNotContainsErrorMessage(str input, str message) {
	set[Message] messages = runBigCheckOn(input);
	if (error(message, _) <- messages) {
		return false;
	}
	return true;
}

private bool verifyContainsNoErrorMessages(str input) {
	return size(runBigCheckOn(input)) == 0;
}


public test bool testInvalidTypes() {
	return checkContainsErrorMessage("StateMachine Test(xxx invalid)",
		"Type xxx is not supported"
		);
}

public test bool testValidStateTransitionChain() {
	set[Message] messages = runFastCheckOn("StateMachine Test T1=\>T2=\>T3? { yes =\> T1 }");
	return size(messages) == 0;
}

private bool checkInvalidTransitionChain(str inp, str forkName) {
	return checkContainsErrorMessage(inp,
		"A fork (<forkName>) cannot be followed by another action or fork."
		);
}
public test bool testInvalidStateTransitionChain() {
	return checkInvalidTransitionChain("StateMachine Test T1=\>T2=\>T3?=\>T4", "T3?");
}
public test bool testInvalidStateTransitionChain2() {
	return checkInvalidTransitionChain("StateMachine Test T1=\>T2=\>T3? { yes =\> T5 } =\>T4", "T3?");
}
public test bool testInvalidStateTransitionChain3() {
	return checkInvalidTransitionChain("StateMachine Test T3? { yes =\> T5 } =\>T4", "T3?");
}
public test bool testInvalidStateTransitionChain4() {
	return checkInvalidTransitionChain("StateMachine Test T3?=\>T4", "T3?");
}
public test bool testInvalidStateTransitionChain5() {
	return checkInvalidTransitionChain("StateMachine Test T3?=\>T4=\>T5", "T3?");
}

public test bool testInvalidForkConditions() {
	return checkContainsErrorMessage("StateMachine Test T? { yes =\> T1 yes =\> T1 }",
		"Fork condition yes is already defined"
		);
}
public test bool testInvalidForkConditionsName() {
	return checkContainsErrorMessage("StateMachine Test T? { ys =\> T1 no =\> T1 }",
		"Fork condition ys is not valid"
		);
}

public test bool testSingleActionNotAllowed() {
	return verifyContainsErrorMessage("StateMachine Test T1 ",
		"Single action T1 has no path to follow"
		);
}
public test bool testSingleActionNotAllowed2() {
	return verifyContainsErrorMessage("StateMachine Test T1? ",
		"Single fork T1? has no path to follow"
		);
}
public test bool testSingleActionNotAllowed2() {
	return verifyNotContainsErrorMessage("StateMachine Test T1? { yes =\> T2 } T2 =\> T1? ",
		"Single action T2 has no path to follow"
		);
}


public test bool testUndefinedEnd() {
	return verifyContainsErrorMessage("StateMachine Test T1 =\> T4 =\> T2",
		"T2 is undefined"
		);
}

public test bool testUndefinedEnd2() {
	return verifyContainsErrorMessage("StateMachine Test T1 =\> T2?",
		"T2? is undefined"
		);
}
public test bool testUndefinedEnd3() {
	return verifyContainsErrorMessage("StateMachine Test T1 =\> T2 T2 =\> T3",
		"T3 is undefined"
		);
}
public test bool testSingleDefineWork() {
	return verifyContainsNoErrorMessages("StateMachine Test T1 =\> T2? T2? { yes =\> T3} T3 =\> T1");
}
public test bool testSingleDefineWork2() {
	return verifyContainsNoErrorMessages("StateMachine Test T1 =\> T2? T2? { yes =\> T1 } ");
}

public test bool testNotTerminating() {
	return verifyContainsErrorMessage("StateMachine Test T1 =\> T2 =\> T1",
		"T1 will never terminate, you should end in a Fork"
		);
}
public test bool testNotTerminating2() {
	return verifyContainsErrorMessage("StateMachine Test T1 =\> !T2? !T2? { yes=\> T1 }",
		"T1 will never terminate, you should end in a Fork"
		);
}

public test bool testWillTerminate() {
	return verifyNotContainsErrorMessage("StateMachine Test T1 =\> !T2? !T2? { yes=\> T1 no =\> T4?} T4? { yes =\> T1 }",
		"T1 will never terminate, you should end in a Fork"
		);
}
public test bool testWillTerminate2() {
	return verifyNotContainsErrorMessage("StateMachine Test T1 =\> !T2?
	!T2? { 
		yes=\> T1 
		no =\> !T4? { 
			yes =\> T1
			no =\> T5?
		}
	}
	T5? { yes =\> T1 } ",
		"T1 will never terminate, you should end in a Fork"
		);
}

public test bool testWillTerminate3() {
	return verifyNotContainsErrorMessage("StateMachine Test T1 =\> T2? { 
		yes=\> T1 
	}
	",
		"T1 will never terminate, you should end in a Fork"
		);
}