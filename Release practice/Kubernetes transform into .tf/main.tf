resource "kubernetes_deployment" "example" {

  metadata {

    name = "terraform-example"

    labels = {

      test = "MyExampleApp"

    }

  }
 
  spec {

    replicas = 2
 
    selector {

      match_labels = {

        test = "MyExampleApp"

      }

    }
 
    template {

      metadata {

        labels = {

          test = "MyExampleApp"

        }

      }
 
      spec {

        container {

          image = "miimagen:0.0.2"

          name  = "example"
 
          resources {

            limits = {

              cpu    = "0.5"

              memory = "512Mi"

            }

            requests = {

              cpu    = "250m"

              memory = "50Mi"

            }

          }

        }

      }

    }

  }

}

