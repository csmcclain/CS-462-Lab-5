import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;
import org.junit.jupiter.api.*;
import org.junit.jupiter.api.Assertions.*;

import java.io.BufferedReader;
import java.io.DataOutputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.lang.reflect.Type;
import java.net.HttpURLConnection;
import java.net.MalformedURLException;
import java.net.ProtocolException;
import java.net.URL;
import java.util.HashMap;
import java.util.Map;
import java.util.Random;

public class Lab5Tests {

    String baseEventUrl = "http://localhost:3000/sky/event/cl07njgi8012c4yao21tqhltu/";
    String baseSkyURL = "http://localhost:3000/sky/cloud/cl07njgi8012c4yao21tqhltu/";

    private void addSensor() throws IOException {
        var url = baseEventUrl + "none/sensor/new_sensor";
        var con = (HttpURLConnection) new URL(url).openConnection();
        con.setRequestMethod("POST");
        con.setRequestProperty("Content-Type", "application/json");

        var status = con.getResponseCode();
        con.disconnect();

        Assertions.assertEquals(200, status);
    }

    private Map<String, String> getSensorMap() throws IOException {
        var url = baseSkyURL + "manage_sensors/sensors";
        var con = (HttpURLConnection) new URL(url).openConnection();
        con.setRequestMethod("POST");
        con.setRequestProperty("Content-Type", "application/json");
        var status = con.getResponseCode();


        BufferedReader in = new BufferedReader(
                new InputStreamReader(con.getInputStream()));
        String inputLine;
        StringBuffer content = new StringBuffer();
        while ((inputLine = in.readLine()) != null) {
            content.append(inputLine);
        }

        in.close();
        con.disconnect();
        Assertions.assertEquals(200, status);

        Type mapType = new TypeToken<Map<String, String>>(){}.getType();
        return new Gson().fromJson(content.toString(), mapType);
    }

    private String getSensorTemperatures() throws IOException {
        var url = baseSkyURL + "manage_sensors/get_temperatures";
        var conn = (HttpURLConnection) new URL(url).openConnection();
        conn.setRequestMethod("POST");
        conn.setRequestProperty("Content-Type", "application/json");
        var status = conn.getResponseCode();


        BufferedReader in = new BufferedReader(
                new InputStreamReader(conn.getInputStream()));
        String inputLine;
        StringBuffer content = new StringBuffer();
        while ((inputLine = in.readLine()) != null) {
            content.append(inputLine);
        }

        in.close();
        conn.disconnect();
        Assertions.assertEquals(200, status);

        return content.toString();
    }

    private void deleteSensor(String sensorName) throws IOException {
        var url = baseEventUrl + "none/sensor/unneeded_sensor";
        var connection = (HttpURLConnection) new URL(url).openConnection();
        connection.setRequestMethod("POST");
        connection.setRequestProperty("Content-Type", "application/json");

        var parameters = new HashMap<String, String>();
        parameters.put("name", sensorName);
        var params = new Gson().toJson(parameters);
        connection.setDoOutput(true);

        var out = new DataOutputStream(connection.getOutputStream());
        out.writeBytes(params);
        out.flush();
        var status = connection.getResponseCode();

        BufferedReader in = new BufferedReader(
                new InputStreamReader(connection.getInputStream()));
        String inputLine;
        StringBuffer content = new StringBuffer();
        while ((inputLine = in.readLine()) != null) {
            content.append(inputLine);
        }

        out.close();
        connection.disconnect();
        Assertions.assertEquals(200, status);
    }


    @Test
    public void testMultSensor() throws IOException, InterruptedException {
        var numPicos = 10;
        for (int i = 0; i < numPicos; i++) {
            addSensor();
        }
        var sensorMap = getSensorMap();
        Assertions.assertEquals(numPicos, sensorMap.keySet().size());

        int randNum = Math.abs(new Random().nextInt()) % sensorMap.keySet().size();

        deleteSensor((String) sensorMap.keySet().toArray()[randNum]);

        sensorMap = getSensorMap();
        Assertions.assertEquals(numPicos - 1, sensorMap.keySet().size());

        Thread.sleep(30000);
        var temperatures = getSensorTemperatures();
        System.out.println(temperatures);

        Assertions.assertNotNull(temperatures);

        for (String name : sensorMap.keySet()) {
            deleteSensor(name);
        }
    }

}
