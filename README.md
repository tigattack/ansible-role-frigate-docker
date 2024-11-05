# Ansible Role: frigate_docker

[![Build Status][build_badge]][build_link]
[![Ansible Galaxy][galaxy_badge]][galaxy_link]

Deploy [Frigate NVR](https://frigate.video/) in a Docker container.

Install the role: `ansible-galaxy role install tigattack.frigate_docker`

See [Example Playbooks](#example-playbooks) below.

## Prerequisites

* [community.docker](https://galaxy.ansible.com/ui/repo/published/community/docker/) Ansible collection. See [requirements.yml](requirements.yml).
* Docker. I recommend the [geerlingguy.docker](https://github.com/geerlingguy/ansible-role-docker) role.
* A chosen data path on the host (this is only used to store the generated htpasswd file).
* A chosen path or Docker volume configuration (e.g. for a CIFS/NFS share) for camera recordings.

## Role Variables

> [!TIP]
> Once installed, you can run `ansible-doc -t role tigattack.frigate_docker` to see role documentation.

### `frigate_docker_container_name`

| Type   | Default       |
|--------|---------------|
| string | `frigate`     |

Frigate container's name.

### `frigate_docker_version`

| Type   | Default  |
|--------|----------|
| string | `stable` |

Frigate Docker image version. Can be `stable` or any other valid image tag (e.g. `stable-tensorrt`, `0.14.0`, etc).

See more at <https://docs.frigate.video/frigate/installation#docker>.

### `frigate_docker_data_bind_path`

| Type | Default                               |
|------|---------------------------------------|
| path | `/opt/<frigate_docker_container_name>`|

Frigate data path on the host.

By default, this is set to `/opt/` followed by the name of the container.

For example:
* If both [`frigate_docker_container_name`](#frigate_docker_container_name) and this variable are left default, the path would be `/opt/frigate`.
* If [`frigate_docker_container_name`](#frigate_docker_container_name) is set to `foo_bar` and this variable is left default, the path would be `/opt/foo_bar`.

### `frigate_docker_storage_bind_path`

| Type | Default                                       |
|------|-----------------------------------------------|
| path | `/opt/<frigate_docker_container_name>_storage`|

> [!WARNING]
> This is mutually exclusive with all other `frigate_docker_storage_*` variables and will only be used if [`frigate_docker_storage_use_docker_volume`](#frigate_docker_storage_use_docker_volume) is `false` (default).

Path to Frigate storage (for recordings etc.) on the host.

By default, this is set to `/opt/` followed by the name of the container, suffixed with `_storage`.

For example:
* If both [`frigate_docker_container_name`](#frigate_docker_container_name) and this variable are left default, the path would be `/opt/frigate_storage`.
* If [`frigate_docker_container_name`](#frigate_docker_container_name) is set to `foo_bar` and this variable is left default, the path would be `/opt/foo_bar`.

### `frigate_docker_storage_use_docker_volume`

| Type   | Default |
|--------|---------|
| bool   | `false` |

> [!WARNING]
> This and the [`frigate_docker_storage_volume`](#frigate_docker_storage_volume) variable are mutually exclusive with the [`frigate_docker_storage_bind_path`](#frigate_docker_storage_bind_path) variable.

Use a Docker volume for Frigate storage (for recordings etc.), instead of a bind mount.

### `frigate_docker_storage_volume`

| Type                   | Default   |
|------------------------|-----------|
| `dict[str, str\|dict]` | See below |

> [!NOTE]
> A Docker volume defined in this variable will only be used if [`frigate_docker_storage_use_docker_volume`](#frigate_docker_storage_use_docker_volume) is `true`.

Dictionary of settings for the Frigate storage Docker volume.

For more information, see <https://docs.ansible.com/ansible/latest/collections/community/docker/docker_volume_module.html>.

#### Keys

* `name`
* `driver`
* `driver_options`

#### Default

```yml
frigate_docker_storage_volume:
  name: frigate_storage
  driver: local
  driver_options: {}
```

#### Example

```yml
frigate_docker_storage_volume:
  name: frigate_storage
  driver: local
  driver_options:
    type: cifs
    device: //store01/data/cctv_recordings
    o: >-
      addr=store01,username=frigate,password=foo_bar,dir_mode=0770,file_mode=0660
```

### `frigate_docker_tmpfs_volume`

| Type | Default     |
|------|-------------|
| path | See below   |

Dictionary of settings for Frigate's tmpfs volume.

#### Default

```yml
frigate_docker_tmpfs_volume:
  target: /tmp/cache
  size: 1000000000
```

### `frigate_docker_shm_size`

| Type   | Default |
|--------|---------|
| string | `64M`   |

Frigate `shm` size. See [Frigate shm size requirements](https://docs.frigate.video/frigate/installation#calculating-required-shm-size).

### `frigate_docker_devices`

| Type        | Default |
|-------------|---------|
| `list[str]` | `[]`    |

Device paths to bind to the Frigate container (for example a GPU or TPU).

### `frigate_docker_ports`

| Type                              | Default   |
|-----------------------------------|-----------|
| `dict[str, dict[str, bool\|int]]` | See below |

Dictionary of settings for Frigate's ports.

#### Keys

* `web_ui`
  * `expose`
  * `port`
* `web_ui_unauth`
  * `expose`
  * `port`
* `rtsp`
  * `expose`
  * `port`
* `webrtc_tcp`
  * `expose`
  * `port`
* `webrtc_udp`
  * `expose`
  * `port`

#### Default

```yml
frigate_docker_ports:
  web_ui:
    expose: true
    port: 8971
  web_ui_unauth:
    expose: false
    port: 5000
  rtsp:
    expose: true
    port: 8554
  webrtc_tcp:
    expose: true
    port: 8555
  webrtc_udp:
    expose: true
    port: 8555
```

### `frigate_docker_container_network`

| Type   | Default   |
|--------|-----------|
| string | `bridge`  |

Name of the Docker network to connect the Frigate container to. The default Docker container network (`bridge`) is used by default.

### `frigate_docker_env_vars`

| Type             | Default |
|------------------|---------|
| `dict[str, str]` | `{}`    |

Environment variables to pass to the Frigate container. Empty dictionary (no env vars) by default.

### `frigate_docker_privileged`

| Type   | Default |
|--------|---------|
| bool   | `false` |

Run the Frigate container in privileged mode. Sometimes useful for granting necessary privileges to various hardware devices, but rarely strictly required.

See the relevant section of the [Frigate documentation](https://docs.frigate.video) for your platform for more information.

### `frigate_docker_config`

| Type   | Default |
|--------|---------|
| dict   | `{}`    |

Frigate configuration. This dictionary's contents are copied to the Frigate config file. Empty dictionary (no config) by default.

## Example Playbooks

**Bare Minimum:**

```yml
---
- name: Deploy Frigate
  hosts: server
  roles:
    - role: tigattack.frigate_docker
```

**With a custom storage volume mount:**

```yml
---
- name: Deploy Frigate
  hosts: server
  roles:
    - role: tigattack.frigate_docker
      vars:
        frigate_docker_storage_use_docker_volume: true
        frigate_docker_storage_volume:
          name: frigate_storage
          driver: local
          driver_options:
            type: cifs
            device: //store01/cctv_recordings
            o: addr=store01,username=frigate,password=foo_bar,dir_mode=0770,file_mode=0660
```

**With defined config:**

```yml
---
- name: Deploy Frigate
  hosts: server
  roles:
    - role: tigattack.frigate_docker
      vars:
        frigate_docker_config:
          mqtt:
            enabled: false
          cameras:
            name_of_your_camera: # <------ Name the camera
              enabled: true
              ffmpeg:
                inputs:
                  - path: rtsp://10.0.10.10:554/rtsp # <----- The stream you want to use for detection
                    roles:
                      - detect
              detect:
                enabled: false # <---- disable detection until you have a working camera feed
                width: 1280
                height: 720
```

## License

MIT

[build_badge]:  https://img.shields.io/github/actions/workflow/status/tigattack/ansible-role-frigate-docker/test.yml?branch=main&label=Lint%20%26%20Test
[build_link]:   https://github.com/tigattack/ansible-role-frigate-docker/actions?query=workflow:Test
[galaxy_badge]: https://img.shields.io/ansible/role/d/tigattack/frigate_docker
[galaxy_link]:  https://galaxy.ansible.com/ui/standalone/roles/tigattack/frigate_docker/
