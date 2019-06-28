local helpers = require "spec.helpers"
local kong_client = require "kong_client.spec.test_helpers"

describe("Add Header", function()
    local kong_sdk, send_request, send_admin_request

    setup(function()
        helpers.start_kong({ custom_plugins = "add-header" })

        kong_sdk = kong_client.create_kong_client()
        send_request = kong_client.create_request_sender(helpers.proxy_client())
        send_admin_request = kong_client.create_request_sender(helpers.admin_client())
    end)

    teardown(function()
        helpers.stop_kong(nil)
    end)

    before_each(function()
        helpers.db:truncate()
    end)

    describe("Plugin config", function()

        local service

        before_each(function()
            service = kong_sdk.services:create({
                name = "test-service",
                url = "http://mockbin:8080/request"
            })
        end)

        context("when config params are given correctly", function()

            it("should create plugin successfully", function()
                local _, response_body = pcall(function()
                    return kong_sdk.plugins:create({
                        service_id = service.id,
                        name = "add-header",
                        config = {
                            header_name = "X-Something",
                            header_value = "Anything"
                        }
                    })
                end)

                assert.are.equal("X-Something", response_body.config.header_name)
                assert.are.equal("Anything", response_body.config.header_value)
            end)
        end)

        context("when config params are missing", function()

            it("should raise error", function()
                local _, response = pcall(function()
                    return kong_sdk.plugins:create({
                        service_id = service.id,
                        name = "add-header",
                        config = {}
                    })
                end)

                assert.are.equal("header_name is required", response.body["config.header_name"])
                assert.are.equal("header_value is required", response.body["config.header_value"])
            end)
        end)

    end)

    describe("Plugin handler", function()

        local service

        before_each(function()
            service = kong_sdk.services:create({
                name = "test-service",
                url = "http://mockbin:8080/request"
            })

            kong_sdk.routes:create_for_service(service.id, "/test")
        end)

        it("should add header to request", function()
            local header_name = "x-something"
            local header_value = "anything"


            kong_sdk.plugins:create({
                service_id = service.id,
                name = "add-header",
                config = {
                    header_name = header_name,
                    header_value = header_value
                }
            })

            local response = send_request({
                method = "GET",
                path = "/test"
            })

            --require'pl.pretty'.dump(response)

            assert.is_equal(header_value, response.body.headers[header_name])
        end)
    end)

end)
