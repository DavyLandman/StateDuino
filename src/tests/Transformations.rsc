module tests::Transformations

import IO;
import String;
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
		iprintln(result);
		return false;
	}
}
public test bool checkGlobalActionsAreNestedRespectingScope() {
	StateMachine result = getSimplified("StateMachine Test start=T1 fork T1 { c1? =\> A1; c2? =\> fork A1 { c2? =\> A1; }  } chain A1 { A2; T1; }");
	if (/fork(_, name(a1Name), [], [path(_, [action(a1Name)])])  := result, startsWith(a1Name, "A1")) {
		return true;
	}
	else {
		iprintln(result);
		return false;
	}
}
public test bool checkChainsAreInsertedIntoNestedForks() {
	StateMachine result = getSimplified("StateMachine Test start=T1 fork T1 { c1? =\> A1; c2? =\> fork F1 { c2? =\> A1; }  } chain A1 { A2; T1; }");
	if (/fork(_, name(f1Name), [], [path(_, [action("A2"), action("T1")])])  := result, startsWith(f1Name, "F1")) {
		return true;
	}
	else {
		iprintln(result);
		return false;
	}
}
public test bool checkChainsAreInsertedIntoNestedNamelessForks() {
	StateMachine result = getSimplified("StateMachine Test start=T1 fork { c1? =\> A1; c2? =\> fork F1 { c2? =\> A1; }  } chain A1 { A2; T1; }");
	if (/fork(_, _, [], [path(_, [action("A2"), action("T1")])])  := result) {
		return true;
	}
	else {
		iprintln(result);
		return false;
	}
}
public test bool checkChainedChainsActionsAreNested() {
	StateMachine result = getSimplified("StateMachine Test start=T1 fork T1 { c1? =\> A1; } chain A1 { A2; A1_2; } chain A1_2 { A3; T1; }");
	if (/fork(_, name("T1"), [], [path(_, [action("A2"), action("A3"), action("T1")])])  := result) {
		return true;
	}
	else {
		iprintln(result);
		return false;
	}
}
public test bool checkChainedChainsActionsAreNested2() {
	StateMachine result = getSimplified("StateMachine Test start=T1 fork T1 { c1? =\> A1; } chain A1 { A2; fork { x? =\> A1_2; } } chain A1_2 { A3; T1; }");
	if (/fork(_, _, [], [path(_, [action("A3"), action("T1")])])  := result) {
		return true;
	}
	else {
		iprintln(result);
		return false;
	}
}

public test bool checkChainsAreNestedInPreActions() {
	StateMachine result = getSimplified("StateMachine Test start=T1 fork T1 {A1; c1? =\> T1; } chain A1 { A2; A3; }");
	if (/fork(_, name("T1"), [action("A2"), action("A3")], _)  := result) {
		return true;
	}
	else {
		iprintln(result);
		return false;
	}
}
public test bool checkGlobalActionsAreNestedWithFork() {
	StateMachine result = getSimplified("StateMachine Test start=T1 fork T1 { c1? =\> A1; } chain A1 { A2; fork T2 { c1? =\> T1; } }");
	if (/fork(_, name("T1"), _, [path(_, [action("A2"), action(t2Name)])])  := result, startsWith(t2Name, "T2")) {
		return true;
	}
	else {
		iprintln(result);
		return false;
	}
}
public test bool checkForkUnnestingWorks() {
	StateMachine result = getSimplified("StateMachine Test start=T1 fork T1 { c1? =\> fork { c2? =\> A1; T1; } } ");
	if (/fork(_, name("T1"), _, [path(_, [action(_)])])  := result) {
		return true;
	}
	else {
		iprintln(result);
		return false;
	}
}
public test bool checkForkUnnestingWorks2() {
	StateMachine result = getSimplified("StateMachine Test start=T1 fork T1 { c1? =\> fork T1 { c2? =\> A1; T1; } } ");
	if (fork(_, name(nm), _, [path(_, [action("A1"), action(nm)])]) <- result.definitions) {
		return true;
	}
	else {
		iprintln(result);
		return false;
	}
}
public test bool checkForkUnnestingWorks3() {
	StateMachine result = getSimplified("StateMachine Test start=T1 fork T1 { c1? =\> fork T1 { c2? =\> fork T2 { c1? =\> A3; T1; } } } ");
	if (/name(t2Name) := result, startsWith(t2Name, "T2"), fork(_, name(nm), _, [path(_, [action(t2Name)])]) <- result.definitions) {
		if (fork(_, _, _, [path(_, [action("A3"), action(nm)])]) <- result.definitions) {
			return true;
		}
		else {
			println("Not respecting shadowing!");
			iprintln(result);
			return false;
		}
	}
	else {
		iprintln(result);
		return false;
	}
}
public test bool checkForkUnnestingWorksWithRenewDefinitions() {
	StateMachine result = getSimplified("StateMachine Test start=T1 fork T1 { c1? =\> fork T1 { c2? =\> A1; fork T1 { c3? =\> A2; T1; } } } ");
	if (fork(_, name(nm), _, [path(_, [action("A2"), action(nm)])]) <- result.definitions) {
		return true;
	}
	else {
		iprintln(result);
		return false;
	}
}


public test bool checkForkUnnestingWorksWhenInsideChains() {
	StateMachine result = getSimplified("StateMachine Test start=T1 fork T1 { c1? =\> C1; } chain C1 { A1; fork T2 { c2? =\> A2; A3; C2; } } chain C2 { fork T3 { c4? =\> A4; A4; T1; } }  ");
	if (/fork(_, name(t2Name), _, [path(_, [action("A2"), action("A3"), action(t3Name)])]) := result, startsWith(t2Name, "T2"), startsWith(t3Name, "T3")) {
		return true;
	}
	else {
		iprintln(result);
		return false;
	}
}

public test bool checkCorrectlyRemovesSelfReferences() {
	StateMachine result = getSimplified("StateMachine Test start=T1 fork T1 { c1? =\> self; }  ");
	if (fork(_, name("T1"), _, [path(_, [action("T1")])]) <- result.definitions) {
		return true;
	}
	else {
		iprintln(result);
		return false;
	}
}
public test bool checkNoDuplicateForks() {
	StateMachine result = getSimplified("StateMachine Test start=T1 fork T1 { c1? =\> C1; } fork T2 { c2? =\> C1; } chain C1 { fork T3 { c3? =\> T1; } } ");
	if (/fork(_, name("T1"), _, [path(_, [action(t3Name)])]) := result, startsWith(t3Name, "T3")) {
		if (fork(_, name("T2"), _, [path(_, [action(t3Name)])]) <- result.definitions) {
			return true;
		}
		else {
			println("Fork was reintroduced");
			iprintln(result);
			return false;	
		}
	}
	else {
		iprintln(result);
		return false;
	}
}
