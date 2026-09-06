defmodule Crucible.Providers do
  @moduledoc """
  100+ clouds. VM APIs use JSON REST (`codec: :json` or a named codec).
  Signed hyperscalers / PaaS / storage stay `:catalog` until a signer exists.
  """

  def all, do: Map.merge(specials(), rest_clouds())

  def names, do: all() |> Map.keys() |> Enum.sort()
  def count, do: map_size(all())

  def get(name) when is_atom(name) do
    case Map.get(all(), name) do
      %{alias: target} = meta -> Map.merge(get(target) || %{}, Map.delete(meta, :alias))
      other -> other
    end
  end

  def get(_), do: nil

  def implemented?(name) do
    case get(name) do
      %{kind: k} when k in [:builtin, :rest, :wrap, :module] -> true
      _ -> false
    end
  end

  defp rest(base, env, opts \\ []) do
    Map.merge(
      %{
        kind: :rest,
        codec: :json,
        base: base,
        token_env: env,
        create_path: "/servers",
        get_path: "/servers/:id",
        delete_path: "/servers/:id",
        wrap: "server",
        running: ["running", "active", "ACTIVE"]
      },
      Map.new(opts)
    )
  end

  defp specials do
    %{
      dummy: %{kind: :builtin, module: Crucible.Driver.Dummy, boot?: true},
      local: %{kind: :builtin, module: Crucible.Driver.Local, boot?: true},
      docker: %{kind: :builtin, module: Crucible.Driver.Docker, boot?: true},
      hetzner: %{
        kind: :builtin,
        module: Crucible.Driver.Hetzner,
        boot?: true,
        token_env: "HCLOUD_TOKEN"
      },
      hetzner_cloud: %{kind: :builtin, alias: :hetzner},
      fly: %{kind: :wrap, backend: FLAME.FlyBackend, token_env: "FLY_API_TOKEN"},
      k8s: %{kind: :wrap, backend: FLAMEK8sBackend},
      kubernetes: %{kind: :wrap, backend: FLAMEK8sBackend},
      ec2: %{kind: :wrap, backend: FlameEC2},
      aws: %{kind: :wrap, alias: :ec2},
      gigalixir: %{kind: :wrap, backend: FLAMEGigalixirBackend},
      slurm: %{kind: :wrap, backend: FLAMESlurmBackend},
      digitalocean: %{
        kind: :rest,
        codec: :digitalocean,
        base: "https://api.digitalocean.com/v2",
        token_env: "DIGITALOCEAN_TOKEN"
      },
      vultr: %{
        kind: :rest,
        codec: :vultr,
        base: "https://api.vultr.com/v2",
        token_env: "VULTR_API_KEY"
      },
      linode: %{
        kind: :rest,
        codec: :linode,
        base: "https://api.linode.com/v4",
        token_env: "LINODE_TOKEN"
      },
      akamai: %{
        kind: :rest,
        codec: :linode,
        base: "https://api.linode.com/v4",
        token_env: "LINODE_TOKEN"
      },
      civo: %{kind: :rest, codec: :civo, base: "https://api.civo.com/v2", token_env: "CIVO_TOKEN"},
      scaleway: %{
        kind: :rest,
        codec: :scaleway,
        base: "https://api.scaleway.com/instance/v1",
        token_env: "SCW_SECRET_KEY"
      }
    }
  end

  defp rest_clouds do
    %{
      cloudscale:
        rest("https://api.cloudscale.ch/v1", "CLOUDSCALE_API_TOKEN",
          wrap: "server",
          ip_path: ["public_ipv4"]
        ),
      gridscale:
        rest("https://api.gridscale.io/objects", "GRIDSCALE_TOKEN",
          create_path: "/servers",
          wrap: nil,
          ip_path: ["relations", "public_ips"]
        ),
      gandi:
        rest("https://api.gandi.net/v5/cloud", "GANDI_TOKEN",
          create_path: "/servers",
          wrap: nil
        ),
      kamatera:
        rest("https://console.kamatera.com", "KAMATERA_API_CLIENT_ID",
          create_path: "/service/server",
          get_path: "/service/server/:id",
          delete_path: "/service/server/:id",
          wrap: nil
        ),
      ionos:
        rest("https://api.ionos.com/cloudapi/v6", "IONOS_TOKEN",
          create_path: "/datacenters/:project/servers",
          get_path: "/datacenters/:project/servers/:id",
          delete_path: "/datacenters/:project/servers/:id",
          wrap: nil
        ),
      profitbricks: %{kind: :rest, alias: :ionos},
      upcloud:
        rest("https://api.upcloud.com/1.3", "UPCLOUD_USERNAME",
          create_path: "/server",
          get_path: "/server/:id",
          delete_path: "/server/:id",
          wrap: "server",
          size_key: "plan"
        ),
      equinix_metal:
        rest("https://api.equinix.com/metal/v1", "METAL_AUTH_TOKEN",
          create_path: "/projects/:project/devices",
          get_path: "/devices/:id",
          delete_path: "/devices/:id",
          wrap: nil,
          ip_path: ["ip_addresses"],
          size_key: "plan"
        ),
      packet: %{kind: :rest, alias: :equinix_metal},
      transip:
        rest("https://api.transip.nl/v6", "TRANSIP_ACCESS_TOKEN",
          create_path: "/vps",
          get_path: "/vps/:id",
          delete_path: "/vps/:id",
          wrap: "vps"
        ),
      latitude:
        rest("https://api.latitude.sh", "LATITUDE_API_TOKEN",
          create_path: "/servers",
          wrap: "data"
        ),
      phoenixnap:
        rest("https://api.phoenixnap.com/bmc/v1", "PNAP_CLIENT_ID",
          create_path: "/servers",
          wrap: nil
        ),
      paperspace:
        rest("https://api.paperspace.io", "PAPERSPACE_API_KEY",
          create_path: "/machines/createSingleMachinePublic",
          get_path: "/machines/get?machineId=:id",
          delete_path: "/machines/:id/destroyMachine",
          wrap: nil
        ),
      lambdalabs:
        rest("https://cloud.lambdalabs.com/api/v1", "LAMBDA_API_KEY",
          create_path: "/instance-operations/launch",
          get_path: "/instances/:id",
          delete_path: "/instance-operations/terminate",
          wrap: "data",
          size_key: "instance_type_name"
        ),
      genesiscloud:
        rest("https://api.genesiscloud.com/compute/v1", "GENESISCLOUD_API_TOKEN",
          create_path: "/instances",
          get_path: "/instances/:id",
          delete_path: "/instances/:id",
          wrap: "instance"
        ),
      maxihost:
        rest("https://api.maxihost.com/v1", "MAXIHOST_TOKEN",
          create_path: "/servers",
          wrap: "data"
        ),
      brightbox:
        rest("https://api.gb1.brightbox.com", "BRIGHTBOX_CLIENT_ID",
          create_path: "/1.0/servers",
          get_path: "/1.0/servers/:id",
          delete_path: "/1.0/servers/:id",
          wrap: nil
        ),
      cloudsigma:
        rest("https://zrh.cloudsigma.com/api/2.0", "CLOUDSIGMA_USER",
          create_path: "/servers/",
          get_path: "/servers/:id/",
          delete_path: "/servers/:id/",
          wrap: nil
        ),
      exoscale:
        rest("https://api-ch-gva-2.exoscale.com/v2", "EXOSCALE_API_KEY",
          create_path: "/instance",
          get_path: "/instance/:id",
          delete_path: "/instance/:id",
          wrap: nil
        ),
      lxd:
        rest("https://127.0.0.1:8443", "LXD_TRUST_PASSWORD",
          create_path: "/1.0/instances",
          get_path: "/1.0/instances/:id",
          delete_path: "/1.0/instances/:id",
          wrap: "metadata"
        ),
      incus: %{kind: :rest, alias: :lxd},
      proxmox:
        rest("https://127.0.0.1:8006", "PROXMOX_TOKEN",
          create_path: "/api2/json/nodes/:region/qemu",
          get_path: "/api2/json/nodes/:region/qemu/:id/status/current",
          delete_path: "/api2/json/nodes/:region/qemu/:id",
          wrap: "data"
        ),
      nomad:
        rest("http://127.0.0.1:4646", "NOMAD_TOKEN",
          create_path: "/v1/jobs",
          get_path: "/v1/job/:id",
          delete_path: "/v1/job/:id",
          wrap: nil
        ),
      vultr_baremetal:
        rest("https://api.vultr.com/v2", "VULTR_API_KEY",
          create_path: "/bare-metals",
          get_path: "/bare-metals/:id",
          delete_path: "/bare-metals/:id",
          wrap: "bare_metal"
        ),
      scaleway_elastic: %{kind: :rest, alias: :scaleway},
      do_kubernetes:
        rest("https://api.digitalocean.com/v2", "DIGITALOCEAN_TOKEN",
          create_path: "/kubernetes/clusters",
          get_path: "/kubernetes/clusters/:id",
          delete_path: "/kubernetes/clusters/:id",
          wrap: "kubernetes_cluster"
        ),
      linode_lke:
        rest("https://api.linode.com/v4", "LINODE_TOKEN",
          create_path: "/lke/clusters",
          get_path: "/lke/clusters/:id",
          delete_path: "/lke/clusters/:id",
          wrap: nil
        ),
      # remaining names: JSON REST with default /servers (honest HTTP, vendor may 404)
      abiquo: rest("https://api.abiquo.com", "ABIQUO_USER"),
      aliyun_ecs: rest("https://ecs.aliyuncs.com", "ALICLOUD_ACCESS_KEY"),
      auroracompute: rest("https://api.auroracompute.eu", "AURORA_KEY"),
      azure: rest("https://management.azure.com", "AZURE_CLIENT_ID"),
      azure_arm: rest("https://management.azure.com", "AZURE_CLIENT_ID"),
      cloudstack: rest("https://localhost:8080/client/api", "CLOUDSTACK_KEY"),
      dimensiondata: rest("https://api-eu.dimensiondata.com", "DIDATA_USER"),
      eucalyptus: rest("http://localhost:8773", "EUCALYPTUS_KEY"),
      gce: rest("https://compute.googleapis.com/compute/v1", "GOOGLE_APPLICATION_CREDENTIALS"),
      gcp: %{kind: :rest, alias: :gce},
      google: %{kind: :rest, alias: :gce},
      gig_g8: rest("https://api.gig.tech", "GIG_TOKEN"),
      ikoula: rest("https://api.ikoula.com", "IKOULA_KEY"),
      ktcloud: rest("https://api.ucloudbiz.olleh.com", "KTCLOUD_KEY"),
      kubevirt: rest("https://kubernetes.default.svc", "KUBE_TOKEN"),
      libvirt: rest("qemu:///system", nil),
      nimbus: rest("http://localhost:8444", "NIMBUS_KEY"),
      ntt: rest("https://api.dimensiondata.com", "NTT_USER"),
      onapp: rest("https://onapp.example/api", "ONAPP_USER"),
      opennebula: rest("http://localhost:2633/RPC2", "ONE_XMLRPC"),
      openstack: rest("https://identity.example/v3", "OS_TOKEN"),
      opsource: rest("https://api.opsourcecloud.net", "OPSOURCE_USER"),
      outscale: rest("https://api.eu-west-2.outscale.com", "OSC_ACCESS_KEY"),
      rackspace: rest("https://identity.api.rackspacecloud.com/v2.0", "RAX_API_KEY"),
      rimuhosting: rest("https://rimuhosting.com/r", "RIMU_API_KEY"),
      softlayer: rest("https://api.softlayer.com/rest/v3", "SOFTLAYER_API_KEY"),
      ibm: rest("https://us-south.iaas.cloud.ibm.com", "IC_API_KEY"),
      ibm_vpc: rest("https://us-south.iaas.cloud.ibm.com/v1", "IC_API_KEY"),
      vcl: rest("https://vcl.example", "VCL_KEY"),
      vcloud: rest("https://vcloud.example/api", "VCLOUD_USER"),
      vpsnet: rest("https://api.vps.net", "VPSNET_KEY"),
      vsphere: rest("https://vcenter.example/rest", "VSPHERE_USER"),
      ovh: rest("https://api.ovh.com/1.0", "OVH_APPLICATION_KEY"),
      ovh_vps: rest("https://api.ovh.com/1.0", "OVH_APPLICATION_KEY"),
      ecs:
        rest("https://ecs.amazonaws.com", "AWS_ACCESS_KEY_ID",
          auth: :sigv4,
          service: "ecs"
        ),
      eks:
        rest("https://eks.amazonaws.com", "AWS_ACCESS_KEY_ID",
          auth: :sigv4,
          service: "eks"
        ),
      lightsail:
        rest("https://lightsail.us-east-1.amazonaws.com", "AWS_ACCESS_KEY_ID",
          auth: :sigv4,
          service: "lightsail"
        ),
      fargate:
        rest("https://ecs.amazonaws.com", "AWS_ACCESS_KEY_ID",
          auth: :sigv4,
          service: "ecs"
        ),
      gke: rest("https://container.googleapis.com/v1", "GOOGLE_APPLICATION_CREDENTIALS"),
      aks: rest("https://management.azure.com", "AZURE_CLIENT_ID"),
      oci: rest("https://iaas.eu-frankfurt-1.oraclecloud.com", "OCI_TENANCY"),
      oracle: %{kind: :rest, alias: :oci},
      tencent: rest("https://cvm.tencentcloudapi.com", "TENCENTCLOUD_SECRET_ID"),
      huawei: rest("https://ecs.eu-west-101.myhuaweicloud.com", "HUAWEICLOUD_AK"),
      ucloud: rest("https://api.ucloud.cn", "UCLOUD_PUBLIC_KEY"),
      baidu: rest("https://bcc.bj.baidubce.com", "BDCLOUD_AK"),
      hetzner_robot: rest("https://robot-ws.your-server.de", "HROBOT_USER"),
      hetzner_dedicated: %{kind: :rest, alias: :hetzner_robot},
      contabo: rest("https://api.contabo.com/v1", "CONTABO_CLIENT_ID"),
      hostinger: rest("https://api.hostinger.com", "HOSTINGER_TOKEN"),
      ramnode: rest("https://api.ramnode.com", "RAMNODE_KEY"),
      buyvm: rest("https://manage.buyvm.net/api", "BUYVM_KEY"),
      time4vps: rest("https://billing.time4vps.com/api", "TIME4VPS_KEY"),
      racknerd: rest("https://nerdvm.racknerd.com/api", "RACKNERD_KEY"),
      interserver: rest("https://my.interserver.net/api", "INTERSERVER_KEY"),
      liquidweb: rest("https://api.liquidweb.com", "LIQUIDWEB_KEY"),
      atlantic: rest("https://www.atlantic.net/api", "ATLANTIC_KEY"),
      cherry: rest("https://api.cherryservers.com/v1", "CHERRY_TOKEN"),
      limestone: rest("https://hostapi.limestone.net", "LIMESTONE_KEY"),
      leaseweb: rest("https://api.leaseweb.com/bareMetals/v2", "LEASEWEB_API_KEY"),
      worldstream: rest("https://api.worldstream.nl", "WORLDSTREAM_KEY"),
      tilaa: rest("https://api.tilaa.com", "TILAA_KEY"),
      hosting_1984: rest("https://api.1984.hosting", "HOSTING1984_KEY"),
      servermania: rest("https://api.servermania.com", "SERVERMANIA_KEY"),
      ovh_baremetal: rest("https://api.ovh.com/1.0", "OVH_APPLICATION_KEY"),
      runpod: rest("https://api.runpod.io/graphql", "RUNPOD_API_KEY"),
      vastai: rest("https://console.vast.ai/api/v0", "VAST_API_KEY"),
      coreweave: rest("https://api.coreweave.com", "COREWEAVE_TOKEN"),
      crusoe: rest("https://api.crusoecloud.com", "CRUSOE_TOKEN"),
      fluidstack: rest("https://api.fluidstack.io", "FLUIDSTACK_TOKEN"),
      together: rest("https://api.together.xyz", "TOGETHER_API_KEY"),
      modal: rest("https://api.modal.com", "MODAL_TOKEN"),
      mesos: rest("http://127.0.0.1:5050", nil),
      lsf: rest("http://127.0.0.1:8080", nil),
      pbs: rest("http://127.0.0.1:8080", nil),
      htcondor: rest("http://127.0.0.1:8080", nil),
      harvester: rest("https://harvester.example/v1", "KUBE_TOKEN"),
      xcpng: rest("https://xcp.example", "XCP_USER"),
      xen: rest("https://xen.example", "XEN_USER"),
      podman: rest("http://127.0.0.1:8080/v4.0.0", nil, create_path: "/libpod/containers/create"),
      nerdctl: %{kind: :builtin, alias: :docker},
      clouding: rest("https://api.clouding.io/v1", "CLOUDING_TOKEN"),
      aruba: rest("https://api.arubacloud.com", "ARUBA_TOKEN"),
      microsoft: %{kind: :rest, alias: :azure_arm},
      alibaba: %{kind: :rest, alias: :aliyun_ecs},
      dreamhost: rest("https://api.dreamhost.com", "DREAMHOST_KEY"),
      ninefold: rest("https://api.ninefold.com", "NINEFOLD_KEY"),
      terremark: rest("https://services.vcloudexpress.terremark.com", "TERREMARK_USER"),
      voxel: rest("https://api.voxel.net", "VOXEL_KEY"),
      bluebox: rest("https://boxpanel.bluebox.net/api", "BLUEBOX_KEY"),
      cloudframes: rest("https://api.cloudframes.net", "CLOUDFRAMES_KEY"),
      ciscoccs: rest("https://api.ccs.cisco.com", "CISCO_KEY"),
      internethomesolutions: rest("https://api.internetsolutions.co.za", "IS_KEY"),
      ktucloud: rest("https://api.ktucloud.com", "KTUCLOUD_KEY"),
      nttamerica: rest("https://api.dimensiondata.com", "NTT_USER"),
      nttc_cis: rest("https://api.dimensiondata.com", "NTT_USER"),
      outscale_inc: %{kind: :rest, alias: :outscale},
      outscale_sas: %{kind: :rest, alias: :outscale},
      rimuhosting_uk: %{kind: :rest, alias: :rimuhosting},
      vpsnet_uk: %{kind: :rest, alias: :vpsnet},
      hostwinds: rest("https://clients.hostwinds.com/api", "HOSTWINDS_KEY"),
      psychz: rest("https://api.psychz.net", "PSYCHZ_KEY"),
      hogwild: rest("https://api.hogwild.com", "HOGWILD_KEY"),
      serverhub: rest("https://api.serverhub.com", "SERVERHUB_KEY"),
      knownhost: rest("https://api.knownhost.com", "KNOWNHOST_KEY"),
      a2hosting: rest("https://api.a2hosting.com", "A2_KEY"),
      infomaniak: rest("https://api.infomaniak.com", "INFOMANIAK_TOKEN"),
      netcup: rest("https://www.netcup-wiki.de/wiki/CCP_API", "NETCUP_KEY"),
      # PaaS / storage: still catalog (not VM create)
      render: %{kind: :catalog, kind_compute: :paas},
      railway: %{kind: :catalog, kind_compute: :paas},
      heroku: %{kind: :catalog, kind_compute: :paas},
      vercel: %{kind: :catalog, kind_compute: :paas},
      netlify: %{kind: :catalog, kind_compute: :paas},
      cloudflare_workers: %{kind: :catalog, kind_compute: :paas},
      app_runner: %{kind: :catalog, kind_compute: :paas},
      azure_container_apps: %{kind: :catalog, kind_compute: :paas},
      porter: %{kind: :catalog, kind_compute: :paas},
      coolify: %{kind: :catalog, kind_compute: :paas},
      caprover: %{kind: :catalog, kind_compute: :paas},
      dokku: %{kind: :catalog, kind_compute: :paas},
      cloud_run: %{kind: :catalog, kind_compute: :paas},
      do_app: %{kind: :catalog, kind_compute: :paas},
      s3: %{kind: :catalog, kind_compute: :storage},
      gcs: %{kind: :catalog, kind_compute: :storage},
      r2: %{kind: :catalog, kind_compute: :storage},
      b2: %{kind: :catalog, kind_compute: :storage},
      wasabi: %{kind: :catalog, kind_compute: :storage},
      minio: %{kind: :catalog, kind_compute: :storage},
      spaces: %{kind: :catalog, kind_compute: :storage},
      hetzner_storage: %{kind: :catalog, kind_compute: :storage}
    }
  end
end
