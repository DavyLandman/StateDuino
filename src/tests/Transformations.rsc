module tests::Transformations

import IO;
import lang::StateDuino::ast::Main;
import lang::StateDuino::ast::Load;
import lang::StateDuino::transformations::Simplify;

private StateMachine getSimplified(str input) {
	return simplify(getStateMachine(input));
}
public test bool checkGlobalActionsAreNested() {
	StateMachine result = getSimplified("StateMachine Test start=T1 T1 =\> T3? T3? { yes =\> T1 }");
	if (/forkDescription(_, [action("yes", chain([action("T1"), fork(normalFork("T3?"))]))]) := result) {
		return true;
	}
	else {
		iprint(result);
		return false;
	}
}
public test bool checkGlobalActionsAreNested2() {
	StateMachine result = getSimplified("StateMachine Test start=T1 T1 =\> T2 T2 =\> T3? { yes =\> T1 }");
	if (/forkDescription(_, [action("yes", chain([action("T1"), action("T2"), fork(normalFork("T3?"))]))]) := result) {
		return true;
	}
	else {
		iprint(result);
		return false;
	}
}

public test bool checkStartActionIsNotRemovedButNested() {
	StateMachine result = getSimplified("StateMachine Test start=T1 T1 =\> T2 T2 =\> T3? { yes =\> T1 }");
	if (chain([action("T1"), action("T2"), fork(normalFork("T3?"))]) <- result.transitions) {
		return true;
	}
	else {
		iprint(result);
		return false;
	}
}
public test bool checkNonStartIsRemoved() {
	StateMachine result = getSimplified("StateMachine Test start=T1 T1 =\> T2 T2 =\> T3? { yes =\> T1 }");
	if (chain([action("T2"), _*]) <- result.transitions) {
		iprint(result);
		return false;
	}
	else {
		return true;
	}
}
public test bool checkNonStartIsRemoved2() {
	StateMachine result = getSimplified("StateMachine Test start=T1 T1 =\> T2 T2 =\> T3? T3? { yes =\> T1 }");
	if (chain([action("T2"), _*]) <- result.transitions) {
		iprint(result);
		return false;
	}
	else {
		return true;
	}
}