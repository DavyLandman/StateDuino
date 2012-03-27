module lang::StateDuino::ast::Full

import IO;
import String;

import lang::StateDuino::ast::Load;
import lang::StateDuino::ast::Main;

public tuple[Coordinator, set[StateMachine]] loadFullStateMachine(loc coordinator) {
	Coordinator coor = getCoordinator(coordinator);
	set[str] machinesToLoad = {nm | invoke(str nm,_) <- coor.invokes};
	set[StateMachine] machines = {};
	for (m <- machinesToLoad) {
		loc mfile = coordinator[file = "<m>.sdo"];
		if (exists(mfile)) {
			machines += {getStateMachine(mfile)};	
		}
		else {
			mfile = coordinator[file = "<toLowerCase(m)>.sdo"];
			if (exists(mfile)) {
				machines += {getStateMachine(mfile)};	
			}
			else {
				throw "Cannot find <m> (I tried <mfile>)";
			}
		}
	}
	return <coor, machines>;
}