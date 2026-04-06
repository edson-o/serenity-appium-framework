package oigo.com.pe.runners;

import io.cucumber.junit.CucumberOptions;
import net.serenitybdd.cucumber.CucumberWithSerenity;
import org.junit.runner.RunWith;



@RunWith(CucumberWithSerenity.class)
@CucumberOptions(features = {"src/test/resources/features"},
        glue = {"oigo.com.pe.stepsdefinitions"},
        tags = {"@Login"}
)
public class CucumberTestSuite {

}
