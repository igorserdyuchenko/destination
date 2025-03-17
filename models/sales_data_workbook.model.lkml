connection: "demo_2" {
  # Define your connection details here
}

  explore: sales_data {
    view_name: sales_data_view

    # Add any necessary joins here if applicable
  }

# model: sales_data_model {
#   include: "*.view"

#   explore: sales_data {
#     view_name: sales_data_view

#     # Add any necessary joins here if applicable
#   }
# }

view: sales_data_view {
  sql_table_name: public.orders ;;

  dimension: order_id {
    sql: ${TABLE}.OrderID ;;
    type: number
    primary_key: yes
  }

  dimension: date {
    sql: ${TABLE}.Date ;;
    type: date
  }

  dimension: category {
    sql: ${TABLE}.Category ;;
    type: string
  }

  dimension: product {
    sql: ${TABLE}.Product ;;
    type: string
  }

  measure: sales {
    sql: SUM(${TABLE}.Sales) ;;
    type: sum
  }

  measure: quantity {
    sql: SUM(${TABLE}.Quantity) ;;
    type: sum
  }
}
