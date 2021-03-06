module lang::StateDuino::ide::Contributions

import util::IDE;
import util::SyntaxHighlightingTemplates;
import ParseTree;
import Message;
import Set;
import IO;
import vis::Figure;

import lang::StateDuino::cst::Parse;
import lang::StateDuino::ast::Load;
import lang::StateDuino::ast::Main;
import lang::StateDuino::semantics::Checker;

public void registerStateDuinoIDE() {

	registerLanguage("The StateDuino language", "sdo", parseStateMachine);
	registerLanguage("The StateDuino Coordinator language", "csdo", parseCoordinator);
	registerContributions("The StateDuino language", {
		getSolarizedLightCategories(),
		categories(("NonBlocking" : {italic()})),
		annotator(Tree (Tree cst) {
			set[Message] messages = performFastCheck(getStateMachine(cst));
			if (size(messages) > 0) {
				return cst[@messages = messages];
			}
			return cst;
		}),
		builder(set[Message] (Tree cst) {
			StateMachine ast = getStateMachine(cst);
			set[Message] messages = performFullCheck(ast);
			return messages;
		})
	});
	registerContributions("The StateDuino Coordinator language", {
		getSolarizedLightCategories()
	});
}