package oigo.com.pe.questions;

import net.serenitybdd.screenplay.Question;
import net.serenitybdd.screenplay.questions.TextContent;
import oigo.com.pe.userinterfaces.Home;

public class ValidacionLogueo {
    
    public static Question<String> home() {
        return actor -> TextContent.of(Home.LABEL_TEXTHOME).viewedBy(actor).asString();
    }

}
