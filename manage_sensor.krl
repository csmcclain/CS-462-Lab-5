ruleset manage_sensor {

    meta {
        use module io.picolabs.wrangler alias wrangler
        shares show_children, show_sensors
    }

    global {
        show_children = function() {
            wrangler:children()
        }

        show_sensors = function() {
            ent:sensors
        }

        generate_name = function() {
            <<Sensor #{wrangler:children().length() + 1}>>
        }
    }

    rule add_sensor {
        select when sensor new_sensor

        pre {
            newSensorName = generate_name()
        }

        fired {
            raise wrangler event "new_child_request" attributes {
                "name": newSensorName,
                "backgroundColor": "#ffa500"
            }
        }
    }

    rule new_sensor_created {
        select when wrangler child_initialized

        pre {
            name = event:attrs{"name"}.klog("sensor_created new child name: ")
            childID = event:attrs{"eci"}.klog("new child eci: ")
        }

        if name && childID then noop()

        fired {
            ent:sensors{name} := childID
            raise sensor event "initialize_wovyn_base" attributes {
                "name": name
            }
        }
    }

    rule initialize_picolabs_emitter_ruleset {
        select when wrangler child_initialized

        pre {
            eci = event:attrs{"eci"}
        }

        event:send(
            {
                "eci": eci,
                "eid": "install-ruleset",
                "domain": "wrangler", "type": "install_ruleset_request",
                "attrs": {
                    "absoluteURL": meta:rulesetURI,
                    "rid": "io.picolabs.wovyn.emitter",
                    "config": {}
                }
            }
        )
    }

    rule initialize_wovyn_ruleset {
        select when wrangler child_initialized

        pre {
            eci = event:attrs{"eci"}
        }

        event:send(
            {
                "eci": eci,
                "eid": "install-ruleset",
                "domain": "wrangler", "type": "install_ruleset_request",
                "attrs": {
                    "absoluteURL": meta:rulesetURI,
                    "rid": "wovyn_base",
                    "config": {}
                }
            }
        )
    }

    rule initialize_temperature_store_ruleset {
        select when wrangler child_initialized

        pre {
            eci = event:attrs{"eci"}
        }

        event:send(
            {
                "eci": eci,
                "eid": "install-ruleset",
                "domain": "wrangler", "type": "install_ruleset_request",
                "attrs": {
                    "absoluteURL": meta:rulesetURI,
                    "rid": "temperature_store",
                    "config": {}
                }
            }
        )
    }
    
    rule initialize_sensor_profile_ruleset {
        select when wrangler child_initialized

        pre {
            eci = event:attrs{"eci"}
        }

        event:send(
            {
                "eci": eci,
                "eid": "install-ruleset",
                "domain": "wrangler", "type": "install_ruleset_request",
                "attrs": {
                    "absoluteURL": meta:rulesetURI,
                    "rid": "sensor_profile",
                    "config": {}
                }
            }
        )
    }

    rule remove_sensor {
        select when sensor remove_sensor

        pre {
            sensorName = event:attrs{"name"}.klog("received sensor name to remove: ")
            eci = ent:sensors.get(sensorName)
            exists = ent:sensors && eci != null
        }

        if exists then noop()

        fired {
            raise wrangler event "child_deletion_request" attributes {
                "eci": eci
            }
            clear ent:sensors{sensorName}
        }
    }


}