return {
    name = "add-header",
    fields = {
        {
            config = {
                type = "record",
                fields = {
                    { header_name = { type = "string", required = true } },
                    { header_value = { type = "string", required = true } }
                }
            }
        }
    }

}