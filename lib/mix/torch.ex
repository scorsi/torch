defmodule Mix.Torch do
  @moduledoc false

  alias Torch.Config

  def parse_config!(task, args) do
    {opts, _, _} = OptionParser.parse(args, switches: [format: :string, app: :string])

    format = convert_format(opts[:format] || Config.template_format())
    otp_app = opts[:app] || Config.otp_app()

    unless otp_app do
      Mix.raise("""
      You need to specify an OTP app to generate files within. Either
      configure it as shown below or pass it in via the `--app` option.

          config :torch,
            otp_app: :my_app

          # Alternatively
          mix #{task} --app my_app
      """)
    end

    unless format in ["eex", "slime"] do
      Mix.raise("""
      Template format is invalid: #{inspect(format)}. Either configure it as
      shown below or pass it via the `--format` option.

          config :torch,
            template_format: :slime

          # Alternatively
          mix #{task} --format slime

      Supported formats: eex, slime
      """)
    end

    %{otp_app: otp_app, format: format}
  end

  def copy_from(source_dir, mapping) when is_list(mapping) do
    for {source_file_path, target_file_path} <- mapping do
      contents =
        [Application.app_dir(:torch), source_dir, source_file_path]
        |> Path.join()
        |> File.read!()

      Mix.Generator.create_file(target_file_path, contents)
    end
  end

  def inject_templates("phx.gen.html", format) do
    copy_from("priv/templates/#{format}/phx.gen.html", [
      {"edit.html.eex", "priv/templates/phx.gen.html/edit.html.eex"},
      {"form.html.eex", "priv/templates/phx.gen.html/form.html.eex"},
      {"index.html.eex", "priv/templates/phx.gen.html/index.html.eex"},
      {"new.html.eex", "priv/templates/phx.gen.html/new.html.eex"},
      {"show.html.eex", "priv/templates/phx.gen.html/show.html.eex"},
    ])
    copy_from("priv/templates/common/phx.gen.html", [
      {"controller_test.exs", "priv/templates/phx.gen.html/controller_test.exs"},
      {"controller.ex", "priv/templates/phx.gen.html/controller.ex"},
      {"view.ex", "priv/templates/phx.gen.html/view.ex"}
    ])
  end

  def inject_templates("phx.gen.context", _format) do
    copy_from("priv/templates/phx.gen.context", [
      {"access_no_schema.ex", "priv/templates/phx.gen.context/access_no_schema.ex"},
      {"context.ex", "priv/templates/phx.gen.context/context.ex"},
      {"schema_access.ex", "priv/templates/phx.gen.context/schema_access.ex"},
      {"test_cases.exs", "priv/templates/phx.gen.context/test_cases.exs"},
      {"context_test.exs", "priv/templates/phx.gen.context/context_test.exs"}
    ])
  end

  def backup_project_templates(mix_task_name) do
    File.rename("priv/templates/#{mix_task_name}", "priv/templates/#{mix_task_name}_backup")
  end

  def restore_project_templates(mix_task_name) do
    File.rename("priv/templates/#{mix_task_name}_backup", "priv/templates/#{mix_task_name}")
  end

  def remove_templates(template_dir) do
    File.rm_rf("priv/templates/#{template_dir}/")
  end

  defp convert_format("slim"), do: "slime"
  defp convert_format(format), do: format
end
