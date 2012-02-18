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

public test bool testInvalidTypes() {
	set[Message] messages = runFastCheckOn("StateMachine Test(xxx invalid)");
	if (size(messages) == 0) {
		return false;	
	}
	if (error("Type xxx is not supported", _) <- messages) {
		return true;
	}
	return false;
}

public test bool testValidStateTransitionChain() {
	set[Message] messages = runFastCheckOn("StateMachine Test T1=\>T2=\>T3?");
	return size(messages) == 0;
}

public test bool testInvalidStateTransitionChain() {
	return checkInvalidTransitionChain("StateMachine Test T1=\>T2=\>T3?=\>T4");
}
public test bool testInvalidStateTransitionChain2() {
	return checkInvalidTransitionChain("StateMachine Test T1=\>T2=\>T3? { yes =\> T5 } =\>T4");
}
public test bool testInvalidStateTransitionChain3() {
	return checkInvalidTransitionChain("StateMachine Test T3? { yes =\> T5 } =\>T4");
}
public test bool testInvalidStateTransitionChain4() {
	return checkInvalidTransitionChain("StateMachine Test T3?=\>T4");
}
public test bool testInvalidStateTransitionChain5() {
	return checkInvalidTransitionChain("StateMachine Test T3?=\>T4=\>T5");
}

private bool checkInvalidTransitionChain(str inp) {
	set[Message] messages = runFastCheckOn(inp);
	if (size(messages) == 0) {
		return false;	
	}
	if (error("A fork cannot be followed by another action or fork.", _) <- messages) {
		return true;
	}
	return false;
}
