var docs = {
    format: function (str, params)
    {
        $.each(params, function (key, value)
        {
            str = str.replace(new RegExp("<<" + key + ">>", "g"), value);
        });

        return str;
    },
    focus: function ()
    {
        $(this).addClass("hover");
    },
    blur: function ()
    {
        $(this).removeClass("hover");
    },
    select: function ()
    {
        $(this).select();
    },
    clickModule: function ()
    {
        $(this).parent().children("dd:first").click();
    },
    clickMethod: function ()
    {
        var data = $(this).data();

        $("#search-value").val(data.action);

        $(this).show().addClass("select").siblings("dd").show().removeClass("select").siblings("dt").addClass("select");
        $(this).parent().siblings().children("dt").removeClass("select").siblings("dd").hide().removeClass("select");

        $("#detail-tabs span:first").click();
        $("#detail-action").html(docs.format("<span>[<<0>>]</span><<1>>", [data.op, data.action]));
        $("#detail-desc").html(data.desc);

        $("#detail-params tr:gt(0)").remove();
        $.each(data.params, function (index, param)
        {
            $("#detail-params").append(docs.format(
                "<tr><td><<0>></td><td><<1>></td><td><<2>></td></tr>", [param.name, param.type, param.desc]
            ));
        });

        $("#detail-errors tr:gt(0)").remove();
        $.each(data.errors, function (index, errCode)
        {
            var errMsg = docsData.errors[errCode];

            if (!errMsg)
            {
                errCode = "unknowErr";
                errMsg = "未知错误";
            }

            $("#detail-errors").append(docs.format(
                "<tr><td><<0>></td><td><<1>></td></tr>", [errCode, errMsg]
            ));
        });

        try
        {
            $("#detail-result").html("").JSONView(data.result);
        }
        catch (e)
        {
            $("#detail-result").html("<strong>Error: invalid json result!</strong>" + data.result);
        }

        $("#test-params div").remove();
        $.each(data.params, function (index, param)
        {
            $("#test-params").append(docs.format(
                "<div><span title='<<0>>(<<1>>)'><<2>>:</span><input name=\"<<2>>\" type=\"text\" class=\"inputText\"/></div>",
                [param.desc, param.type, param.name]
            ));
        });

        $("#test-params input[name='op']").val(data.op);
        $("#test-return").html("<strong>please enter params and submit!</strong>");
    },
    clickTab: function ()
    {
        var index = $("#detail-tabs span").index($(this));
        $(this).addClass("select").siblings().removeClass("select");
        $("#detail-content").children().eq(index).show().siblings().hide();
    },
    doTest: function ()
    {
        var params = {};

        $.each($("#test-params input"), function (key, input)
        {
            params[input.name] = input.value;
        });

        $("#test-return").html("<strong>loading...</strong>");
        $.ajax({
            url: "/lua",
            type: "GET",
            data: params,
            timeout: 5000,
            success: function (data)
            {
                try
                {
                    $("#test-return").JSONView(data);
                }
                catch (e)
                {
                    $("#test-return").html("<strong>Error: invalid json result!</strong>");
                }
            },
            error: function ()
            {
                $("#test-return").html("<strong>Error: server return invalid content!</strong>");
            }
        });
    },
    search: function ()
    {
        var action = $.trim($("#search-value").val());

        if ($.isNumeric(action))
        {
            action = docsData.ops[action] ? docsData.ops[action] : "";
        }

        if (action != "")
        {
            var method = $(docs.format("#method-<<0>>-<<1>>", action.split(".")));

            if (method)
            {
                method.click();
            }
        }
    },
    init: function ()
    {
        var ops = Object.keys(docsData.ops).sort(function (op1, op2)
        {
            return parseInt(op1) - parseInt(op2);
        });

        $.map(ops, function (op)
        {
            var items = docsData.ops[op].split(".");
            var module = items[0];
            var method = items[1];
            var moduleInfo = docsData.modules[module];
            var methodInfo = moduleInfo.methods[method];

            if ($("#method-" + module).length == 0)
            {
                $("#method-list").append($("<div>", {id: "method-" + module}).append($("<dt>", {
                    html: moduleInfo.desc,
                    mouseover: docs.focus,
                    mouseout: docs.blur,
                    click: docs.clickModule
                })));
            }

            $("#method-" + module).append($("<dd>", {
                id: ["method", module, method].join("-"),
                html: "<span>[" + op + "]</span> " + methodInfo.desc,
                data: methodInfo,
                mouseover: docs.focus,
                mouseout: docs.blur,
                click: docs.clickMethod
            }).hide());
        });

        // 搜索事件
        $("#search-value").focus(docs.select);
        $("#search-value").keyup(function (event)
        {
            if (event.which == 13)
            {
                docs.search();
            }
        });
        $("#search-submit").click(docs.search);

        // Tab切换
        $("#detail-tabs span").click(docs.clickTab);

        // 测试提交
        $("#test-submit").click(docs.doTest);

        // 打开首个接口
        $("#method-list").children(":first").children(":first").click();
    }
};

$(document).ready(function ()
{
    // 更新标题
    $(document).attr('title', $(document).attr('title') + " ( 版本: " + docsData.version + " )");

    // 初始化
    docs.init();
});