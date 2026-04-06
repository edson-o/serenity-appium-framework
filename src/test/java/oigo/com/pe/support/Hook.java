package oigo.com.pe.support;

import com.alicorp.productounico.utils.TestCasesStatusForReportDevAzure;
import io.cucumber.java.After;
import io.cucumber.java.Before;
import net.serenitybdd.screenplay.Actor;
import net.serenitybdd.screenplay.actors.OnStage;
import net.serenitybdd.screenplay.actors.OnlineCast;

public class Hook {
    private static int totalScenarios = 0;
    private static int completedScenarios = 0;

    @ParameterType(".*")
    public Actor actor(String actorName) {
        return OnStage.theActorCalled(actorName);
    }


    @Before
    public void setTheStage() {
        OnStage.setTheStage(new OnlineCast());
    }


    @After
    public void afterScenario(Scenario scenario) {
        totalScenarios++;
        completedScenarios++;
        TestCasesStatusForReportDevAzure.add(scenario.getName(), scenario.isFailed());
        if (completedScenarios == totalScenarios) {
            TestCasesStatusForReportDevAzure.imprimirResumenFinal();
        }
    }

}
