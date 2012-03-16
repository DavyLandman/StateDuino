module tests::Transformations

import IO;
import lang::StateDuino::ast::Main;
import lang::StateDuino::ast::Load;
import lang::StateDuino::transformations::Simplify;

private StateMachine getSimplified(str input) {
	return simplify(getStateMachine(input));
}
public test bool checkGlobalActionsAreNested() {
	StateMachine result = getSimplified("StateMachine Test start=T1 fork T1 { c1? =\> A1; } chain A1 { A2; T1; }");
	if (/fork(_, name("T1"), [], [path(_, [action("A2"), action("T1")])])  := result) {
		return true;
	}
	else {
		iprint(result);
		return false;
	}
}
public test bool checkGlobalActionsAreNestedRespectingScope() {
	StateMachine result = getSimplified("StateMachine Test start=T1 fork T1 { c1? =\> A1; c2? =\> fork A1 { c2? =\> A1; }  } chain A1 { A2; T1; }");
	if (/fork(_, name("A1"), [], [path(_, [action("A1")])])  := result) {
		return true;
	}
	else {
		iprint(result);
		return false;
	}
}
public test bool checkGlobalActionsAreNestedWithFork() {
	StateMachine result = getSimplified("StateMachine Test start=T1 fork T1 { c1? =\> A1; } chain A1 { A2; fork T2 { c1? =\> T1; } }");
	if (/fork(_, name("T1"), _, [path(_, [action("A2"), fork(_,name("T2"), _, _)])])  := result) {
		return true;
	}
	else {
		iprint(result);
		return false;
	}
}
/*
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
public test bool checkForkIsUnnested() {
	StateMachine result = getSimplified("StateMachine Test start=T1 T1 =\> T2 T2 =\> T3? { yes =\> T1 }");
	if (chain([forkDescription(normalFork("T3?"), _)]) <- result.transitions) {
		return true;
	}
	else {
		iprint(result);
		return false;
	}
}



public test bool testNestedForkDefinitionsAreAlsoMovedUp() {
	StateMachine result = getSimplified("StateMachine Test start=T1? T1? { yes =\> !T2? } !T2? { yes =\> T1? { yes =\> !T2? } }");
	if (chain([forkDescription(normalFork("T1??"), [action(_, chain([fork(nonBlockingFork("!T2?"))]))])]) <- result.transitions) {
		return true;
	}
	else {
		//iprint(result);
		return false;
	}
}
*/