write_files:
  - path: /opt/oracle/10.2.0/network/admin/tnsnames.ora
    owner: root:root
    permissions: 0644
    content: |
      %{ for db in tnsnames }${ db.name } =
        (DESCRIPTION =
          (ADDRESS_LIST =
            (ADDRESS = (PROTOCOL = TCP)(HOST = ${ db.address })(PORT = ${ db.port }))
          )
          (CONNECT_DATA =
            (SERVICE_NAME = ${ db.service_name })
            (SERVER = DEDICATED)
          )
        )
      %{ endfor }
