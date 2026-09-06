defmodule CrucibleTest do
  use ExUnit.Case, async: false

  test "local driver boots and shuts down" do
    {:ok, state} = Crucible.init(driver: :local)
    {:ok, machine, state} = Crucible.boot(state, %{})
    assert machine.driver == :local
    assert is_pid(machine.pid)
    {:ok, info} = Crucible.describe(state, machine)
    assert info.driver == :local
    assert :ok = Crucible.shutdown(state, machine)
  end

  test "AWS SigV4 signs authorization" do
    {:ok, dt, _} = DateTime.from_iso8601("2015-08-30T12:36:00Z")

    headers =
      Crucible.Auth.SigV4.sign(
        :get,
        "https://iam.amazonaws.com/?Action=ListUsers&Version=2010-05-08",
        [],
        "",
        access_key: "AKIDEXAMPLE",
        secret_key: "wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY",
        region: "us-east-1",
        service: "iam",
        datetime: dt
      )

    auth =
      Enum.find_value(headers, fn
        {"authorization", v} -> v
        _ -> nil
      end)

    assert String.starts_with?(auth, "AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/")
    assert auth =~ "Signature="
  end

  test "ecs REST uses sigv4 and accepts injected HTTP" do
    http = fn method, url, opts ->
      assert method == :post
      assert url =~ "ecs.amazonaws.com"

      auth =
        opts
        |> Keyword.get(:headers, [])
        |> Enum.find_value(fn {k, v} -> if String.downcase(k) == "authorization", do: v end)

      assert is_binary(auth)

      {:ok,
       %{
         status: 200,
         body: %{"server" => %{"id" => "t", "status" => "running", "ip" => "10.0.0.1"}}
       }}
    end

    {:ok, state} =
      Crucible.init(
        driver: :ecs,
        http: http,
        access_key: "AKIA",
        secret_key: "secret"
      )

    {:ok, m, _state} = Crucible.boot(state, %{name: "n"})
    assert m.driver == :ecs
  end

  test "CLI install paths" do
    assert is_binary(Crucible.CLI.Paths.bin_dir())
  end

  test "CLI help and version" do
    assert :ok = Crucible.CLI.main(["--help"], halt: false)
    assert :ok = Crucible.CLI.main(["version"], halt: false)
  end

  test "CLI lists providers" do
    assert :ok = Crucible.CLI.main(["providers", "--implemented"], halt: false)
  end

  test "CLI boots dummy" do
    assert :ok = Crucible.CLI.main(["boot", "--driver", "dummy", "--name", "cli1"], halt: false)
  end

  test "CLI missing driver errors" do
    assert {:error, :driver_required} = Crucible.CLI.main(["boot"], halt: false)
  end

  test "CLI sizes for dummy" do
    assert :ok = Crucible.CLI.main(["sizes", "--driver", "dummy"], halt: false)
  end

  test "CLI json providers" do
    assert :ok = Crucible.CLI.main(["providers", "--json", "--kind", "builtin"], halt: false)
  end

  test "HTTP client is gale or req or none" do
    assert Crucible.HTTP.client() in [:gale, :req, :none]
  end

  test "drivers map includes local" do
    d = Crucible.drivers()
    assert d.local
    assert d.dummy
    assert d.hetzner
    assert is_boolean(d.docker)
    assert is_boolean(d.fly)
  end

  test "catalog has 100+ clouds" do
    names = Crucible.providers()
    assert length(names) >= 100
    assert :digitalocean in names
    assert :hetzner in names
    assert :proxmox in names
    assert Crucible.get_driver(:digitalocean) == Crucible.Driver.REST
    assert Crucible.get_driver(:render) == Crucible.Driver.Catalog
    assert Crucible.get_driver(:cloudscale) == Crucible.Driver.REST
    assert Crucible.get_driver(:proxmox) == Crucible.Driver.REST
  end

  test "catalog driver is honest about not implemented" do
    {:ok, state} = Crucible.init(driver: :render)
    assert {:error, {:not_implemented, :render, _}} = Crucible.boot(state, %{})
  end

  test "json REST codec boots cloudscale via injected HTTP" do
    http = fn
      :post, url, _ ->
        assert url =~ "api.cloudscale.ch"

        {:ok,
         %{
           status: 201,
           body: %{
             "server" => %{
               "id" => "cs1",
               "name" => "n",
               "status" => "changing",
               "public_ipv4" => nil
             }
           }
         }}

      :get, url, _ ->
        assert url =~ "/servers/cs1"

        {:ok,
         %{
           status: 200,
           body: %{
             "server" => %{
               "id" => "cs1",
               "name" => "n",
               "status" => "running",
               "public_ipv4" => "203.0.113.11"
             }
           }
         }}

      :delete, _url, _ ->
        {:ok, %{status: 204, body: %{}}}
    end

    {:ok, state} = Crucible.init(driver: :cloudscale, http: http, token: "t")
    {:ok, m, state} = Crucible.boot(state, %{name: "n"})
    {:ok, m, state} = Crucible.await(state, m, 1_000)
    assert m.driver == :cloudscale
    assert m.ip == "203.0.113.11"
    assert :ok = Crucible.shutdown(state, m)
  end

  test "digitalocean REST codec via injected HTTP" do
    http = fn
      :post, url, _ ->
        assert url =~ "/droplets"

        {:ok,
         %{
           status: 202,
           body: %{
             "droplet" => %{
               "id" => 7,
               "name" => "d1",
               "status" => "new",
               "networks" => %{"v4" => []}
             }
           }
         }}

      :get, url, _ ->
        assert url =~ "/droplets/7"

        {:ok,
         %{
           status: 200,
           body: %{
             "droplet" => %{
               "id" => 7,
               "name" => "d1",
               "status" => "active",
               "networks" => %{"v4" => [%{"type" => "public", "ip_address" => "203.0.113.10"}]}
             }
           }
         }}

      :delete, url, _ ->
        assert url =~ "/droplets/7"
        {:ok, %{status: 204, body: %{}}}
    end

    {:ok, state} = Crucible.init(driver: :digitalocean, http: http, token: "t")
    {:ok, m, state} = Crucible.boot(state, %{name: "d1"})
    {:ok, m, state} = Crucible.await(state, m, 1_000)
    assert m.driver == :digitalocean
    assert m.ip == "203.0.113.10"
    assert :ok = Crucible.shutdown(state, m)
  end

  test "dummy driver is Libcloud DummyNodeDriver shaped" do
    assert Crucible.get_driver(:dummy) == Crucible.Driver.Dummy
    {:ok, state} = Crucible.init(driver: :dummy)
    {:ok, m1, state} = Crucible.boot(state, %{name: "n1"})
    assert m1.state == :running
    assert m1.ip =~ "127.0.0."
    {:ok, m2, state} = Crucible.boot(state, %{})
    assert m1.id != m2.id
    assert :ok = Crucible.shutdown(state, m1)
    assert Crucible.NodeState.running?(:running)
    assert %Crucible.Size{id: "cx22"} = %Crucible.Size{id: "cx22", ram: 4096}
  end

  test "FLAME backend local spawn" do
    {:ok, state} = Crucible.FLAME.Backend.init(driver: :local)
    {:ok, _term, state} = Crucible.FLAME.Backend.remote_boot(state)
    parent = self()

    assert {:ok, {pid, ref}} =
             Crucible.FLAME.Backend.remote_spawn_monitor(state, fn ->
               send(parent, :ok)
             end)

    assert is_pid(pid)
    assert is_reference(ref)
    assert_receive :ok, 1_000
  end

  test "docker without image errors" do
    {:ok, state} = Crucible.init(driver: :docker)

    result = Crucible.boot(state, %{})

    assert result in [
             {:error, :docker_image_required},
             {:error, {:driver_unavailable, :docker}}
           ] or match?({:error, {:docker_run_failed, _, _}}, result)
  end

  test "hetzner boots via injected HTTP" do
    http = fn
      :post, url, _opts ->
        assert url =~ "/servers"

        {:ok,
         %{
           status: 201,
           body: %{
             "server" => %{
               "id" => 99,
               "name" => "c1",
               "status" => "initializing",
               "public_net" => %{"ipv4" => %{"ip" => "203.0.113.9"}}
             }
           }
         }}

      :get, url, _opts ->
        assert url =~ "/servers/99"

        {:ok,
         %{
           status: 200,
           body: %{
             "server" => %{
               "id" => 99,
               "name" => "c1",
               "status" => "running",
               "public_net" => %{"ipv4" => %{"ip" => "203.0.113.9"}}
             }
           }
         }}

      :delete, url, _opts ->
        assert url =~ "/servers/99"
        {:ok, %{status: 204, body: %{}}}
    end

    {:ok, state} = Crucible.init(driver: :hetzner, http: http, token: "test")
    {:ok, machine, state} = Crucible.boot(state, %{name: "c1", env: %{"FLAME_PARENT" => "x"}})
    assert machine.driver == :hetzner
    assert machine.id == "99"
    {:ok, machine, state} = Crucible.await(state, machine, 1_000)
    assert machine.state == :running
    assert machine.ip == "203.0.113.9"
    assert :ok = Crucible.shutdown(state, machine)
  end

  test "hetzner without token errors" do
    {:ok, state} = Crucible.init(driver: :hetzner, token: nil)
    assert {:error, :hetzner_token_required} = Crucible.boot(state, %{})
  end

  test "wrap fly without terminator_sup is not ready" do
    case Crucible.init(driver: :fly) do
      {:error, {:driver_unavailable, _}} ->
        :ok

      {:ok, state} ->
        assert {:error, {:provisioner_not_ready, _}} = Crucible.boot(state, %{})
    end
  end
end
